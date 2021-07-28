#ifndef FOO_H
#define FOO_H

typedef nx_struct foo_msg {
  nx_uint16_t counter;
  nx_uint8_t id;
} foo_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif

