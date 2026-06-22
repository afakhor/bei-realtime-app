#include <string>
#include <thread>
#include <atomic>

std::atomic<bool> running(false);
std::string json_data = "{\"market_open\":false,\"stocks\":{},\"trades\":[]}";

void feed_loop() {
    while (running) {
        // Paksa isi data dummy biar ga kosong
        json_data = R"({
            "market_open":false,
            "stocks":{
                "BBCA":{"o":10250,"h":10300,"l":10200,"c":10250,"v":1000000},
                "TLKM":{"o":3480,"h":3520,"l":3470,"c":3500,"v":800000}
            },
            "trades":[]
        })";
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
}

extern "C" {
void start_feed() {
    if (!running) {
        running = true;
        std::thread(feed_loop).detach();
    }
}

const char* get_all_data() {
    return json_data.c_str();
}
}