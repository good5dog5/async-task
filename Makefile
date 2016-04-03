EXEC = \
	test-async \
	test-reactor \
	test-buffer \
	test-protocol-server \
	httpd

ifeq ($(strip $(PROFILE)), 1)
PROF_FLAGS = -pg
CFLAGS += $(PROF_FLAGS)
LDFLAGS += $(PROF_FLAGS)
endif

OUT ?= .build
.PHONY: all
all: $(OUT) $(EXEC)

CC ?= gcc
CFLAGS = -std=gnu99 -Wall  -O2 -g -I .
LDFLAGS = -lpthread 

OBJS := \
	async.o \
	reactor.o \
	buffer.o \
	protocol-server.o
deps := $(OBJS:%.o=%.o.d)
OBJS := $(addprefix $(OUT)/,$(OBJS))
deps := $(addprefix $(OUT)/,$(deps))

httpd: $(OBJS) httpd.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

httpd-pre: protocol-server.c httpd.c
	$(CC) $(CFLAGS) -E -P  $^ $(LDFLAGS)

test-%: $(OBJS) tests/test-%.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OUT)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ -MMD -MF $@.d $<

$(OUT):
	@mkdir -p $@

doc:
	@doxygen

bench:
	@./httpd &> log &
	@ab -c 32 -n 100 http://localhost:8080/

clean:
	$(RM) $(EXEC) $(OBJS) $(deps)
	@rm -rf $(OUT)

distclean: clean
	rm -rf html

-include $(deps)
