#include "sendAck.h"

configuration sendAckAppC {}

implementation {

  components MainC, sendAckC as App;
  components new TimerMilliC() as Timer;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components ActiveMessageC;
  components new FakeSensorC();


  App.Boot -> MainC.Boot;
  App.Timer -> Timer;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.SplitControl -> ActiveMessageC;
  App.Packet -> AMSenderC;
  App.PacketAcknowledgements -> AMSenderC;
  App.Read -> FakeSensorC;

}

