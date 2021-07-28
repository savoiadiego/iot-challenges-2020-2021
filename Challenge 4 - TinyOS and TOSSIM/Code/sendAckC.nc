#include "sendAck.h"
#include "Timer.h"

module sendAckC {

  uses {
	interface Boot;
	interface Timer<TMilli> as Timer;
	interface AMSend;
	interface Receive;
    interface SplitControl;
	interface Packet;
    interface PacketAcknowledgements;
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter = 0;
  message_t packet;

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {
	sensor_msg_t* mess = (sensor_msg_t*)(call Packet.getPayload(&packet, sizeof(sensor_msg_t)));
  	if(mess == NULL){
  		return;
  	}
  	
  	mess->msg_type = 1;
  	mess->msg_counter = counter;
  	
  	if(call PacketAcknowledgements.requestAck(&packet) == SUCCESS) {
  		if(call AMSend.send(2, &packet, sizeof(sensor_msg_t)) == SUCCESS){
  			dbg("radio", "REQ sent with counter %d\n", mess->msg_counter);
  			counter++;
  		}
  	}
 }        

  //****************** Send response function *****************//
  void sendResp() {
	call Read.read();
  }

  //******************** Boot interface ***********************//
  event void Boot.booted() {
	dbg("boot","Application booted on mote %u\n", TOS_NODE_ID);
    call SplitControl.start();
  }

  //**************** SplitControl interface *******************//
  event void SplitControl.startDone(error_t err){
    if(err == SUCCESS) {
	  	dbg("radio", "Radio ON!\n");
	  	if(TOS_NODE_ID == 1) {
	  		call Timer.startPeriodic(1000);
	  	}
  	} else{
  	dbgerror("radio", "Radio error, trying to turning on again...\n");
  		call SplitControl.start();
  	}
  }
  
  event void SplitControl.stopDone(error_t err){}

  //******************* Timer interface **********************//
  event void Timer.fired() {
  	 sendReq();
  }
  
  //********************* AMSend interface *******************//
  event void AMSend.sendDone(message_t* bufPtr, error_t err) {
	 if(&packet == bufPtr) {
  		dbg("radio", "Packet sent at time %s\n", sim_time_string());
  		if(call PacketAcknowledgements.wasAcked(&packet)) {
  			call Timer.stop();
  		} else{
  			dbg("radio", "Packet not acknowledged\n");
  		}
  	
  	 } else{
  		dbgerror("radio", "Radio error!!!\n");
  	 }
  }

  //********************** Receive interface *****************//
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
	if(len != sizeof(sensor_msg_t)) {
  		dbgerror("radio", "Packet malformed\n");
  		return bufPtr;
  	}else {
  		sensor_msg_t* mess = (sensor_msg_t*)payload;
  		
  		dbg("radio", "Received a message at time %s\n", sim_time_string());
  		dbg_clear("packet", "\t\tType: %u\n", mess->msg_type);
  		dbg_clear("packet", "\t\tCounter: %u\n", mess->msg_counter);
  		dbg_clear("packet", "\t\tValue: %u\n", mess->value);
  		
  		if(mess->msg_type == 1) {
  			counter = mess->msg_counter;
  			sendResp();
  		}
  		
  		return bufPtr;  	
  	}
  }
  
  //******************** Read interface ********************//
  event void Read.readDone(error_t result, uint16_t data) {
	sensor_msg_t* mess = (sensor_msg_t*)(call Packet.getPayload(&packet, sizeof(sensor_msg_t)));
  	if(mess == NULL){
  		return;
  	}
  	
  	mess->msg_type = 2;
  	mess->msg_counter = counter;
  	mess->value = data;
  	
  	if(call PacketAcknowledgements.requestAck(&packet) == SUCCESS) {
  		if(call AMSend.send(1, &packet, sizeof(sensor_msg_t)) == SUCCESS){
  			dbg("radio", "RESP sent\n");
  		}
  	}
  }

}
