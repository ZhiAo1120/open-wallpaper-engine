// Portable jthread/stop_token replacement for Apple libc++ which lacks C++20
// std::jthread support. Uses std::atomic<bool> + std::thread underneath.
#pragma once

#include <atomic>
#include <functional>
#include <mutex>
#include <thread>
#include <utility>

namespace wallpaper::audio::compat
{

class stop_token
{
public:
    stop_token() noexcept = default;

    bool stop_requested() const noexcept { return pStop_->load(std::memory_order_acquire); }

    // Intentionally not exposing stop_requested from source; only need the token side.
    class StopSource
    {
    public:
        StopSource() : pStop_(std::make_shared<std::atomic<bool>>(false)) {}

        bool stop_requested() const noexcept { return pStop_->load(std::memory_order_acquire); }

        bool request_stop()
        {
            bool expected = false;
            return pStop_->compare_exchange_strong(expected, true, std::memory_order_release);
        }

        stop_token token() const noexcept
        {
            stop_token t;
            t.pStop_ = pStop_;
            return t;
        }

    private:
        std::shared_ptr<std::atomic<bool>> pStop_;
    };

private:
    std::shared_ptr<std::atomic<bool>> pStop_ { std::make_shared<std::atomic<bool>>(false) };
    friend class StopSource;
};

class jthread
{
public:
    jthread() noexcept = default;

    template <typename F, typename... Args>
    explicit jthread(F&& f, Args&&... args)
    {
        stop_source_ = stop_token::StopSource();
        auto tok = stop_source_.token();
        thread_ = std::thread([fn = std::forward<F>(f), tok](auto&&... a) mutable {
            fn(tok, std::forward<decltype(a)>(a)...);
        },
            std::forward<Args>(args)...);
    }

    jthread(jthread&& other) noexcept
        : thread_(std::move(other.thread_))
        , stop_source_(std::move(other.stop_source_))
    {
    }

    jthread& operator=(jthread&& other) noexcept
    {
        if (this != &other) {
            request_stop_and_join();
            thread_ = std::move(other.thread_);
            stop_source_ = std::move(other.stop_source_);
        }
        return *this;
    }

    ~jthread()
    {
        request_stop_and_join();
    }

    bool joinable() const noexcept { return thread_.joinable(); }

    void join() { thread_.join(); }

    void request_stop()
    {
        stop_source_.request_stop();
    }

    stop_token get_stop_token() const noexcept { return stop_source_.token(); }

private:
    void request_stop_and_join()
    {
        if (thread_.joinable()) {
            stop_source_.request_stop();
            thread_.join();
        }
    }

    std::thread thread_ {};
    stop_token::StopSource stop_source_ {};
};

} // namespace wallpaper::audio::compat
