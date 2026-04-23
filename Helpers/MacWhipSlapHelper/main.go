package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"runtime"
	"strings"
	"time"

	"github.com/taigrr/apple-silicon-accelerometer/detector"
	"github.com/taigrr/apple-silicon-accelerometer/sensor"
	"github.com/taigrr/apple-silicon-accelerometer/shm"
)

const (
	sensorStartupDelay = 100 * time.Millisecond
	pollInterval       = 10 * time.Millisecond
	maxBatchSize       = 200
)

func main() {
	var cfg config
	flag.Float64Var(&cfg.threshold, "threshold", 0.05, "minimum amplitude threshold in g")
	flag.DurationVar(&cfg.cooldown, "cooldown", 750*time.Millisecond, "cooldown between slap events")
	flag.StringVar(&cfg.eventFile, "event-file", "", "path to append slap events")
	flag.StringVar(&cfg.readyFile, "ready-file", "", "path to touch after startup")
	flag.StringVar(&cfg.stopFile, "stop-file", "", "path whose existence requests shutdown")
	flag.Parse()

	if err := run(context.Background(), cfg); err != nil {
		appendLine(cfg.eventFile, "error "+sanitize(err.Error()))
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

type config struct {
	threshold float64
	cooldown  time.Duration
	eventFile string
	readyFile string
	stopFile  string
}

func run(ctx context.Context, cfg config) error {
	if runtime.GOOS != "darwin" {
		return errors.New("macOS only")
	}
	if runtime.GOARCH != "arm64" {
		return errors.New("Apple Silicon only")
	}
	if os.Geteuid() != 0 {
		return errors.New("accelerometer access requires root")
	}
	if cfg.eventFile == "" || cfg.readyFile == "" || cfg.stopFile == "" {
		return errors.New("--event-file, --ready-file, and --stop-file are required")
	}

	accelRing, err := shm.CreateRing(shm.NameAccel)
	if err != nil {
		return fmt.Errorf("create accelerometer shared memory: %w", err)
	}
	defer accelRing.Close()
	defer accelRing.Unlink()

	sensorErr := make(chan error, 1)
	go func() {
		if runErr := sensor.Run(sensor.Config{
			AccelRing: accelRing,
			Restarts:  0,
		}); runErr != nil {
			sensorErr <- runErr
		}
	}()

	time.Sleep(sensorStartupDelay)
	appendLine(cfg.eventFile, "ready")
	_ = os.WriteFile(cfg.readyFile, []byte(time.Now().Format(time.RFC3339Nano)), 0o644)

	det := detector.New()
	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()

	var lastTotal uint64
	var lastEventTime time.Time
	var lastAccepted time.Time

	for {
		select {
		case <-ctx.Done():
			appendLine(cfg.eventFile, "stopped")
			return nil
		case err := <-sensorErr:
			return fmt.Errorf("sensor worker failed: %w", err)
		case <-ticker.C:
		}

		if _, err := os.Stat(cfg.stopFile); err == nil {
			appendLine(cfg.eventFile, "stopped")
			return nil
		}

		samples, newTotal := accelRing.ReadNew(lastTotal, shm.AccelScale)
		lastTotal = newTotal
		if len(samples) == 0 {
			continue
		}
		if len(samples) > maxBatchSize {
			samples = samples[len(samples)-maxBatchSize:]
		}

		now := time.Now()
		tNow := float64(now.UnixNano()) / 1e9
		for idx, sample := range samples {
			tSample := tNow - float64(len(samples)-idx-1)/float64(det.FS)
			det.Process(sample.X, sample.Y, sample.Z, tSample)
		}

		if len(det.Events) == 0 {
			continue
		}

		event := det.Events[len(det.Events)-1]
		if event.Time.Equal(lastEventTime) {
			continue
		}
		lastEventTime = event.Time

		if event.Amplitude < cfg.threshold {
			continue
		}
		if !lastAccepted.IsZero() && time.Since(lastAccepted) < cfg.cooldown {
			continue
		}
		lastAccepted = now

		appendLine(
			cfg.eventFile,
			fmt.Sprintf("slap timestamp=%s amplitude=%.6f severity=%s", now.Format(time.RFC3339Nano), event.Amplitude, sanitize(event.Severity)),
		)
	}
}

func appendLine(path string, line string) {
	if path == "" {
		return
	}

	f, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		return
	}
	defer f.Close()

	_, _ = fmt.Fprintln(f, line)
}

func sanitize(value string) string {
	value = strings.ReplaceAll(value, "\n", " ")
	value = strings.ReplaceAll(value, "\r", " ")
	return value
}
