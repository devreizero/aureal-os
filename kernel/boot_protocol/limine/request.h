#ifndef REQUEST_H
#define REQUEST_H

#include <limine.h>

extern uint64_t limine_base_revision[3];  //   LIMINE_BASE_REVISION

// Expose the requests declared in request.c
extern volatile struct limine_framebuffer_request framebufferRequest;
extern volatile struct limine_rsdp_request rsdpRequest;
extern volatile struct limine_memmap_request memmapRequest;
extern volatile struct limine_mp_request mpRequest;
extern volatile struct limine_stack_size_request stackSizeRequest;
extern volatile struct limine_executable_address_request executableAddressRequest;
extern volatile struct limine_hhdm_request hhdmRequest;

#endif
