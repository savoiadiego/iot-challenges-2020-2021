#ifndef SENDACK_H
#define SENDACK_H

//Value field: REQ=1; RESP=2
typedef nx_struct sensor_msg {
	nx_uint8_t msg_type;
	nx_uint16_t msg_counter;
	nx_uint16_t value;
} sensor_msg_t; 

enum{
AM_RADIO_COUNT_MSG = 6,
};

#endif

