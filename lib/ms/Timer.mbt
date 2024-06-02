// class Timer : public Singleton<Timer> {
// public:
//     Timer() { start(); }

//     ~Timer() override = default;

//     // Start the timer by setting the last measurement to now.
//     void start() { point = clock::now(); }

//     // Return time elapsed since the last measurement.
//     int64_t stop() {
//         clock::time_point last = point;
//         point = clock::now();

//         auto duration =
//             std::chrono::duration_cast<std::chrono::microseconds>(point - last);
//         return duration.count();
//     }

// private:
//     using clock = std::chrono::high_resolution_clock;

//     clock::time_point point;
// };

// Small class for measuring elapsed time between game loops.
// Time measures are in microseconds.
struct Timer {
  mut point : Int64
}

fn Timer::new() -> Timer {
  { point: 0L }
}

fn start(self : Timer, nowMicro : Int64) -> Unit {
  self.point = nowMicro
}

fn stop(self : Timer, nowMicro : Int64) -> Int64 {
  let duration = nowMicro - self.point
  self.point = nowMicro
  duration
}
// // Small class for measuring elapsed time given a specific start time.
// class ContinuousTimer : public Singleton<ContinuousTimer> {
// public:
//     using point = std::chrono::time_point<std::chrono::steady_clock>;

//     ContinuousTimer() { start(); }

//     ~ContinuousTimer() override = default;

//     // Return now from the clock to be used to calculate elapsed time later.
//     point start() { return clock::now(); }

//     // Return time elapsed since the last measurement provided.
//     int64_t stop(point last) {
//         auto now = clock::now();

//         auto duration =
//             std::chrono::duration_cast<std::chrono::microseconds>(now - last);
//         return duration.count();
//     }

// private:
//     using clock = std::chrono::steady_clock;
// };
