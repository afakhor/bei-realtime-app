#include <cstdint>

extern "C" {

__attribute__((visibility("default"))) __attribute__((used))
int32_t native_add(int32_t a, int32_t b) {
    return a + b;
}

__attribute__((visibility("default"))) __attribute__((used))
void start_feed() {
    // nanti isi websocket disini
}

__attribute__((visibility("default"))) __attribute__((used))
const char* get_last_tick() {
    return "{\"code\":\"BBCA\",\"price\":10250}";
}

}
