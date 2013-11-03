//
//  AppDelegate.m
//  TransVibrator-MIDI-Connector
//
//  Created by Toru Nayuki on 2013/11/03.
//  Copyright (c) 2013年 Toru Nayuki. All rights reserved.
//

#import "AppDelegate.h"

#import <CoreMIDI/CoreMIDI.h>

#include "libusb.h"

@interface AppDelegate ()

{
    libusb_device_handle *libUSBDevHandle;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    libusb_init(NULL);
    libUSBDevHandle = libusb_open_device_with_vid_pid(NULL, 0x0b49, 0x064f);
    
    MIDIClientRef midiClientRef;
    int result = MIDIClientCreate(CFSTR("TransVibrator MIDI Connector"), MyMIDINotifyProc, (__bridge void *)(self), &midiClientRef);
    
    MIDIEndpointRef midiEndpointRef;
    result = MIDIDestinationCreate(midiClientRef, CFSTR("TransVibrator"), MyMIDIReadProc, (__bridge void *)(self), &midiEndpointRef);
}

void MyMIDINotifyProc(const MIDINotification *message, void *refCon)
{
}

static void MyMIDIReadProc(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon)
{
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;

    for (int i = 0; i < pktlist->numPackets; i++) {
        Byte midiStatus = packet->data[0];
        Byte midiCommand = midiStatus >> 4;

        int value = 0;
        if (midiCommand == 0x09) {
            Byte note = packet->data[1] & 0x7F;
            Byte velocity = packet->data[2] & 0x7F;

            value = velocity == 0 ? 0 : (note * 2) << 8 | note << 1;
        } else if (midiCommand == 0x08) {
            value = 0;
        } else {
            packet = MIDIPacketNext(packet);

            continue;
        }

        libusb_control_transfer(((__bridge AppDelegate *)readProcRefCon)->libUSBDevHandle, 0x41, 0x00, value, 0x300 + value & 0xf, NULL, 0, 1000);
        
        packet = MIDIPacketNext(packet);
    }
}

@end
