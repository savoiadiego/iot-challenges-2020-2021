#include "Timer.h"
#include "foo.h"
#include "printf.h"

module fooC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}

implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      if (TOS_NODE_ID == 1) {
      	call MilliTimer.startPeriodic(1000);
      }
      else if (TOS_NODE_ID == 2) {
      	call MilliTimer.startPeriodic(333);
      }
      else if (TOS_NODE_ID == 3) {
      	call MilliTimer.startPeriodic(200);
      }
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
    if (locked) {return;}
    else {
      foo_msg_t* msg = (foo_msg_t*)call Packet.getPayload(&packet, sizeof(foo_msg_t));
      
      if (msg == NULL) {return;}
      
      msg->counter = counter;
      msg->id = TOS_NODE_ID;
      
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(foo_msg_t)) == SUCCESS) {
		locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    if (len != sizeof(foo_msg_t)) {return bufPtr;}
    else {
      foo_msg_t* msg = (foo_msg_t*)payload;
      counter++;
      
      if ((msg->counter % 10) == 0) {
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
		printf("Mote %d sets its leds to 000\n", TOS_NODE_ID);
		printfflush();
      }
      else if (msg->id == 1) {
		call Leds.led0Toggle();
		printf("Mote %d toggles led0\n", TOS_NODE_ID);
		printfflush();
      }
      else if (msg->id == 2) {
		call Leds.led1Toggle();
		printf("Mote %d toggles led1\n", TOS_NODE_ID);
		printfflush();
      }
      else if (msg->id == 3) {
		call Leds.led2Toggle();
		printf("Mote %d toggles led2\n", TOS_NODE_ID);
		printfflush();
      }
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }
}

