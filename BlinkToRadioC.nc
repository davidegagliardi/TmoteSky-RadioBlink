// $Id: BlinkToRadioC.nc,v 1.5 2007/09/13 23:10:23 scipio Exp $

/*
 * "Copyright (c) 2000-2006 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Implementation of the BlinkToRadio application.  A counter is
 * incremented and a radio message is sent whenever a timer fires.
 * Whenever a radio message is received, the three least significant
 * bits of the counter in the message payload are displayed on the
 * LEDs.  Program two motes with this application.  As long as they
 * are both within range of each other, the LEDs on both will keep
 * changing.  If the LEDs on one (or both) of the nodes stops changing
 * and hold steady, then that node is no longer receiving any messages
 * from the other node.
 *
 * @author Prabal Dutta
 * @date   Feb 1, 2006
 */
#include <Timer.h>
#include "BlinkToRadio.h"

module BlinkToRadioC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
// Interfacce utilizzate per la gestione della radio
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation {

// Dichiarazione variabili
  uint16_t counter;
  message_t pkt;
  bool busy = FALSE;

// Funzione che rappresenta sui led il valore che gli viene passato come parametro
  void setLeds(uint16_t val) {
    call Leds.set(val);
  }

  event void Boot.booted() {
// Accendo la radio per la comunicazione
    call AMControl.start();
  }

// Entro in questo evento  quando la radio ha finito lo start
  event void AMControl.startDone(error_t err) {
// Se è andato a buon fine faccio partre il timer0
    if (err == SUCCESS) {
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
// Altrimenti ritento lo start
    } else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

// Scatta il timer 0
  event void Timer0.fired() {
    counter++;
// Se non sto inviando nessun pachetto
    if (!busy) {
// Dichiaro il pacchetto da inviare
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
      if (btrpkt == NULL) {
	return;
      }
// Setto i campi del pacchetto
      btrpkt->nodeid = TOS_NODE_ID;
      btrpkt->counter = counter;
// Invio il pacchetto e segnalo come occupata la radio (busy = TRUE)
      if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
      }
    }
  }

// Finito l'invio del messaggio, segnalo la radio come libera (busy = TRUE)
  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

// Entro in questo evento se ricevo un messaggio
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
// Se il pacchetto ricevuto ha la lunghezza uguale a quella del pacchetto che attendo ricevo il messaggio, e chiamo la funzione che mi visualizzerà sui led il contatore contenuto nel pacchetto
    if (len == sizeof(BlinkToRadioMsg)) {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
      setLeds(btrpkt->counter);
    }
    return msg;
  }
}
