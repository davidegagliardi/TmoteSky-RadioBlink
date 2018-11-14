// $Id: BlinkToRadio.h,v 1.4 2006/12/12 18:22:52 vlahan Exp $

#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

enum {
// Indentificativo del pacchetto inviato sulla rete
  AM_BLINKTORADIO = 0x95,
// Costante di tempo con la quale verranno utilizzati i timer
  TIMER_PERIOD_MILLI = 250,
  TIMER_PERIOD_MILLI2 = 1000
};

// Struttura del pacchetto che verrà inviato sul canale radio
typedef nx_struct BlinkToRadioMsg {
  nx_uint16_t nodeid;
  nx_uint16_t counter;
} BlinkToRadioMsg;

#endif
