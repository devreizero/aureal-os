#include "common/kernel.h"
#include "common/serial.h"

static void onBeforeInit() {
    initSerial(115200 / 9600);
}

ArchCallback archOnBeforeInit = onBeforeInit;