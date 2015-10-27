# HG changeset patch
# Parent c69e3682800ab96ff627bceb566e5ccf37661afd

diff --git a/configs/common/FSConfig.py b/configs/common/FSConfig.py
--- a/configs/common/FSConfig.py
+++ b/configs/common/FSConfig.py
@@ -647,7 +647,7 @@
     return self
 
 
-def makeMultiRoot(testSystem,
+def makeDistRoot(testSystem,
                   rank,
                   size,
                   server_name,
@@ -660,10 +660,10 @@
     self = Root(full_system = True)
     self.testsys = testSystem
 
-    self.etherlink = MultiEtherLink(speed = linkspeed,
+    self.etherlink = DistEtherLink(speed = linkspeed,
                                     delay = linkdelay,
-                                    multi_rank = rank,
-                                    multi_size = size,
+                                    dist_rank = rank,
+                                    dist_size = size,
                                     server_name = server_name,
                                     server_port = server_port,
                                     sync_start = sync_start,
@@ -674,7 +674,7 @@
     elif hasattr(testSystem, 'tsunami'):
         self.etherlink.int0 = Parent.testsys.tsunami.ethernet.interface
     else:
-        fatal("Don't know how to connect MultiEtherLink to this system")
+        fatal("Don't know how to connect DistEtherLink to this system")
 
     if dumpfile:
         self.etherdump = EtherDump(file=dumpfile)
diff --git a/configs/common/Options.py b/configs/common/Options.py
--- a/configs/common/Options.py
+++ b/configs/common/Options.py
@@ -275,29 +275,29 @@
     # Benchmark options
     parser.add_option("--dual", action="store_true",
                       help="Simulate two systems attached with an ethernet link")
-    parser.add_option("--multi", action="store_true",
-                      help="Parallel multi gem5 simulation.")
+    parser.add_option("--dist", action="store_true",
+                      help="Parallel distributed gem5 simulation.")
     parser.add_option("--is-switch", action="store_true")
-    parser.add_option("--multi-rank", default=0, action="store", type="int",
-                      help="Rank of this system within the multi gem5 run.")
-    parser.add_option("--multi-size", default=0, action="store", type="int",
-                      help="Number of gem5 processes within the multi gem5 run.")
-    parser.add_option("--multi-server-name",
+    parser.add_option("--dist-rank", default=0, action="store", type="int",
+                      help="Rank of this system within the dist gem5 run.")
+    parser.add_option("--dist-size", default=0, action="store", type="int",
+                      help="Number of gem5 processes within the dist gem5 run.")
+    parser.add_option("--dist-server-name",
                       default="127.0.0.1",
                       action="store", type="string",
                       help="Name of the message server host\nDEFAULT: localhost")
-    parser.add_option("--multi-server-port",
+    parser.add_option("--dist-server-port",
                       default=2200,
                       action="store", type="int",
                       help="Message server listen port\nDEFAULT: 2200")
-    parser.add_option("--multi-sync-repeat",
+    parser.add_option("--dist-sync-repeat",
                       default="0us",
                       action="store", type="string",
-                      help="Repeat interval for synchronisation barriers among multi gem5 processes\nDEFAULT: --ethernet-linkdelay")
-    parser.add_option("--multi-sync-start",
+                      help="Repeat interval for synchronisation barriers among dist-gem5 processes\nDEFAULT: --ethernet-linkdelay")
+    parser.add_option("--dist-sync-start",
                       default="5200000000000t",
                       action="store", type="string",
-                      help="Time to schedule the first multi synchronisation barrier\nDEFAULT:5200000000000t")
+                      help="Time to schedule the first dist synchronisation barrier\nDEFAULT:5200000000000t")
     parser.add_option("-b", "--benchmark", action="store", type="string",
                       dest="benchmark",
                       help="Specify the benchmark to run. Available benchmarks: %s"\
diff --git a/configs/example/fs.py b/configs/example/fs.py
--- a/configs/example/fs.py
+++ b/configs/example/fs.py
@@ -328,15 +328,15 @@
 if len(bm) == 2:
     drive_sys = build_drive_system(np)
     root = makeDualRoot(True, test_sys, drive_sys, options.etherdump)
-elif len(bm) == 1 and options.multi:
-    # This system is part of a multi-gem5 simulation
-    root = makeMultiRoot(test_sys,
-                         options.multi_rank,
-                         options.multi_size,
-                         options.multi_server_name,
-                         options.multi_server_port,
-                         options.multi_sync_repeat,
-                         options.multi_sync_start,
+elif len(bm) == 1 and options.dist:
+    # This system is part of a dist-gem5 simulation
+    root = makeDistRoot(test_sys,
+                         options.dist_rank,
+                         options.dist_size,
+                         options.dist_server_name,
+                         options.dist_server_port,
+                         options.dist_sync_repeat,
+                         options.dist_sync_start,
                          options.ethernet_linkspeed,
                          options.ethernet_linkdelay,
                          options.etherdump);
diff --git a/configs/example/sw.py b/configs/example/sw.py
--- a/configs/example/sw.py
+++ b/configs/example/sw.py
@@ -1,4 +1,4 @@
-# Copyright (c) 2015 The University of Wisconsin Madison
+# Copyright (c) 2015 The University of Illinois Urbana Champaign
 # All rights reserved
 #
 # The license below extends only to copyright in the software and shall
@@ -35,8 +35,8 @@
 #
 # Authors: Mohammad Alian
 
-# This is an example of an n port network switch (star topology) to work in
-# pd-gem5. Users can extend this to have different different topologies
+# This is an example of an n port network switch to work in dist-gem5.
+# Users can extend this to have different different topologies
 
 import optparse
 import sys
@@ -54,19 +54,19 @@
 def build_switch(options):
     # instantiate an EtherSwitch with "num_node" ports. Also pass along
     # timing parameters
-    switch = EtherSwitch(port_count = options.multi_size)
+    switch = EtherSwitch(port_count = options.dist_size)
     # instantiate etherlinks to connect switch box ports to ethertap objects
-    switch.portlink = [MultiEtherLink(speed = options.ethernet_linkspeed,
+    switch.portlink = [DistEtherLink(speed = options.ethernet_linkspeed,
                                       delay = options.ethernet_linkdelay,
-                                      multi_rank = options.multi_rank,
-                                      multi_size = options.multi_size,
-                                      server_name = options.multi_server_name,
-                                      server_port = options.multi_server_port,
-                                      sync_start = options.multi_sync_start,
-                                      sync_repeat = options.multi_sync_repeat,
+                                      dist_rank = options.dist_rank,
+                                      dist_size = options.dist_size,
+                                      server_name = options.dist_server_name,
+                                      server_port = options.dist_server_port,
+                                      sync_start = options.dist_sync_start,
+                                      sync_repeat = options.dist_sync_repeat,
                                       is_switch = True,
-                                      num_nodes = options.multi_size)
-                       for i in xrange(options.multi_size)]
+                                      num_nodes = options.dist_size)
+                       for i in xrange(options.dist_size)]
 
     for (i, link) in enumerate(switch.portlink):
         link.int0 = switch.interface[i]
diff --git a/src/dev/Ethernet.py b/src/dev/Ethernet.py
--- a/src/dev/Ethernet.py
+++ b/src/dev/Ethernet.py
@@ -58,18 +58,18 @@
     speed = Param.NetworkBandwidth('1Gbps', "link speed")
     dump = Param.EtherDump(NULL, "dump object")
 
-class MultiEtherLink(EtherObject):
-    type = 'MultiEtherLink'
-    cxx_header = "dev/multi_etherlink.hh"
+class DistEtherLink(EtherObject):
+    type = 'DistEtherLink'
+    cxx_header = "dev/dist_etherlink.hh"
     int0 = SlavePort("interface 0")
     delay = Param.Latency('0us', "packet transmit delay")
     delay_var = Param.Latency('0ns', "packet transmit delay variability")
     speed = Param.NetworkBandwidth('1Gbps', "link speed")
     dump = Param.EtherDump(NULL, "dump object")
-    multi_rank = Param.UInt32('0', "Rank of this gem5 process (multi run)")
-    multi_size = Param.UInt32('1', "Number of gem5 processes (multi run)")
-    sync_start = Param.Latency('5200000000000t', "first multi sync barrier")
-    sync_repeat = Param.Latency('10us', "multi sync barrier repeat")
+    dist_rank = Param.UInt32('0', "Rank of this gem5 process (dist run)")
+    dist_size = Param.UInt32('1', "Number of gem5 processes (dist run)")
+    sync_start = Param.Latency('5200000000000t', "first dist sync barrier")
+    sync_repeat = Param.Latency('10us', "dist sync barrier repeat")
     server_name = Param.String('localhost', "Message server name")
     server_port = Param.UInt32('2200', "Message server port")
     is_switch = Param.Bool(False, "true if this a link in etherswitch")
diff --git a/src/dev/SConscript b/src/dev/SConscript
--- a/src/dev/SConscript
+++ b/src/dev/SConscript
@@ -61,8 +61,8 @@
 Source('etherdump.cc')
 Source('etherint.cc')
 Source('etherlink.cc')
-Source('multi_iface.cc')
-Source('multi_etherlink.cc')
+Source('dist_iface.cc')
+Source('dist_etherlink.cc')
 Source('tcp_iface.cc')
 Source('etherpkt.cc')
 Source('ethertap.cc')
diff --git a/src/dev/dist_etherlink.cc b/src/dev/dist_etherlink.cc
new file mode 100644
--- /dev/null
+++ b/src/dev/dist_etherlink.cc
@@ -0,0 +1,272 @@
+/*
+ * Copyright (c) 2015 ARM Limited
+ * All rights reserved
+ *
+ * The license below extends only to copyright in the software and shall
+ * not be construed as granting a license to any other intellectual
+ * property including but not limited to intellectual property relating
+ * to a hardware implementation of the functionality of the software
+ * licensed hereunder.  You may use the software subject to the license
+ * terms below provided that you ensure that this notice is replicated
+ * unmodified and in its entirety in all distributions of the software,
+ * modified or unmodified, in source code or in binary form.
+ *
+ * Redistribution and use in source and binary forms, with or without
+ * modification, are permitted provided that the following conditions are
+ * met: redistributions of source code must retain the above copyright
+ * notice, this list of conditions and the following disclaimer;
+ * redistributions in binary form must reproduce the above copyright
+ * notice, this list of conditions and the following disclaimer in the
+ * documentation and/or other materials provided with the distribution;
+ * neither the name of the copyright holders nor the names of its
+ * contributors may be used to endorse or promote products derived from
+ * this software without specific prior written permission.
+ *
+ * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
+ * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
+ * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
+ * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
+ * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
+ * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
+ * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
+ * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
+ * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
+ * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
+ * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
+ *
+ * Authors: Gabor Dozsa
+ */
+
+/* @file
+ * Device module for a full duplex ethernet link for dist gem5 simulations.
+ */
+
+#include "dev/dist_etherlink.hh"
+
+#include <arpa/inet.h>
+#include <sys/socket.h>
+#include <unistd.h>
+
+#include <cmath>
+#include <deque>
+#include <string>
+#include <vector>
+
+#include "base/random.hh"
+#include "base/trace.hh"
+#include "debug/DistEthernet.hh"
+#include "debug/DistEthernetPkt.hh"
+#include "debug/EthernetData.hh"
+#include "dev/dist_iface.hh"
+#include "dev/etherdump.hh"
+#include "dev/etherint.hh"
+#include "dev/etherlink.hh"
+#include "dev/etherobject.hh"
+#include "dev/etherpkt.hh"
+#include "dev/tcp_iface.hh"
+#include "params/EtherLink.hh"
+#include "sim/core.hh"
+#include "sim/serialize.hh"
+#include "sim/system.hh"
+
+using namespace std;
+
+DistEtherLink::DistEtherLink(const Params *p)
+    : EtherObject(p)
+{
+    DPRINTF(DistEthernet,"DistEtherLink::DistEtherLink() "
+            "link delay:%llu ticksPerByte:%f\n", p->delay, p->speed);
+
+    txLink = new TxLink(name() + ".link0", this, p->speed, p->delay_var,
+                        p->dump);
+    rxLink = new RxLink(name() + ".link1", this, p->delay, p->dump);
+
+    Tick sync_repeat;
+    if (p->sync_repeat != 0) {
+        if (p->sync_repeat != p->delay)
+            warn("DistEtherLink(): sync_repeat is %lu and linkdelay is %lu",
+                 p->sync_repeat, p->delay);
+        sync_repeat = p->sync_repeat;
+    } else {
+        sync_repeat = p->delay;
+    }
+
+    // create the dist (TCP) interface to talk to the peer gem5 processes.
+    distIface = new TCPIface(p->server_name, p->server_port,
+                              p->dist_rank, p->dist_size,
+                              p->sync_start, sync_repeat, this, p->is_switch,
+                              p->num_nodes);
+
+    localIface = new LocalIface(name() + ".int0", txLink, rxLink, distIface);
+}
+
+DistEtherLink::~DistEtherLink()
+{
+    delete txLink;
+    delete rxLink;
+    delete localIface;
+    delete distIface;
+}
+
+EtherInt*
+DistEtherLink::getEthPort(const std::string &if_name, int idx)
+{
+    if (if_name != "int0") {
+        return nullptr;
+    } else {
+        panic_if(localIface->getPeer(), "interface already connected to");
+    }
+    return localIface;
+}
+
+void
+DistEtherLink::serialize(CheckpointOut &cp) const
+{
+    distIface->serializeSection(cp, "distIface");
+    txLink->serializeSection(cp, "txLink");
+    rxLink->serializeSection(cp, "rxLink");
+}
+
+void
+DistEtherLink::unserialize(CheckpointIn &cp)
+{
+    distIface->unserializeSection(cp, "distIface");
+    txLink->unserializeSection(cp, "txLink");
+    rxLink->unserializeSection(cp, "rxLink");
+}
+
+void
+DistEtherLink::init()
+{
+    DPRINTF(DistEthernet,"DistEtherLink::init() called\n");
+    distIface->init();
+}
+
+void
+DistEtherLink::startup()
+{
+    DPRINTF(DistEthernet,"DistEtherLink::startup() called\n");
+    distIface->startup();
+}
+
+void
+DistEtherLink::RxLink::setDistInt(DistIface *m)
+{
+    assert(!distIface);
+    distIface = m;
+    // Spawn a new receiver thread that will process messages
+    // coming in from peer gem5 processes.
+    // The receive thread will also schedule a (receive) doneEvent
+    // for each incoming data packet.
+    distIface->spawnRecvThread(&doneEvent, linkDelay);
+}
+
+void
+DistEtherLink::RxLink::rxDone()
+{
+    assert(!busy());
+
+    // retrieve the packet that triggered the receive done event
+    packet = distIface->packetIn();
+
+    if (dump)
+        dump->dump(packet);
+
+    DPRINTF(DistEthernetPkt, "DistEtherLink::DistLink::rxDone() "
+            "packet received: len=%d\n", packet->length);
+    DDUMP(EthernetData, packet->data, packet->length);
+
+    localIface->sendPacket(packet);
+
+    packet = nullptr;
+}
+
+void
+DistEtherLink::TxLink::txDone()
+{
+    if (dump)
+        dump->dump(packet);
+
+    packet = nullptr;
+    assert(!busy());
+
+    localIface->sendDone();
+}
+
+bool
+DistEtherLink::TxLink::transmit(EthPacketPtr pkt)
+{
+    if (busy()) {
+        DPRINTF(DistEthernet, "packet not sent, link busy\n");
+        return false;
+    }
+
+    packet = pkt;
+    Tick delay = (Tick)ceil(((double)pkt->length * ticksPerByte) + 1.0);
+    if (delayVar != 0)
+        delay += random_mt.random<Tick>(0, delayVar);
+
+    // send the packet to the peers
+    assert(distIface);
+    distIface->packetOut(pkt, delay);
+
+    // schedule the send done event
+    parent->schedule(doneEvent, curTick() + delay);
+
+    return true;
+}
+
+void
+DistEtherLink::Link::serialize(CheckpointOut &cp) const
+{
+    bool packet_exists = (packet != nullptr);
+    SERIALIZE_SCALAR(packet_exists);
+    if (packet_exists)
+        packet->serialize("packet", cp);
+
+    bool event_scheduled = event->scheduled();
+    SERIALIZE_SCALAR(event_scheduled);
+    if (event_scheduled) {
+        Tick event_time = event->when();
+        SERIALIZE_SCALAR(event_time);
+    }
+}
+
+void
+DistEtherLink::Link::unserialize(CheckpointIn &cp)
+{
+    bool packet_exists;
+    UNSERIALIZE_SCALAR(packet_exists);
+    if (packet_exists) {
+        packet = make_shared<EthPacketData>(16384);
+        packet->unserialize("packet", cp);
+    }
+
+    bool event_scheduled;
+    UNSERIALIZE_SCALAR(event_scheduled);
+    if (event_scheduled) {
+        Tick event_time;
+        UNSERIALIZE_SCALAR(event_time);
+        parent->schedule(*event, event_time);
+    }
+}
+
+DistEtherLink::LocalIface::LocalIface(const std::string &name,
+                                       TxLink *tx,
+                                       RxLink *rx,
+                                       DistIface *m) :
+    EtherInt(name), txLink(tx)
+{
+    tx->setLocalInt(this);
+    rx->setLocalInt(this);
+    tx->setDistInt(m);
+    rx->setDistInt(m);
+}
+
+DistEtherLink *
+DistEtherLinkParams::create()
+{
+    return new DistEtherLink(this);
+}
+
+
diff --git a/src/dev/dist_etherlink.hh b/src/dev/dist_etherlink.hh
new file mode 100644
--- /dev/null
+++ b/src/dev/dist_etherlink.hh
@@ -0,0 +1,234 @@
+/*
+ * Copyright (c) 2015 ARM Limited
+ * All rights reserved
+ *
+ * The license below extends only to copyright in the software and shall
+ * not be construed as granting a license to any other intellectual
+ * property including but not limited to intellectual property relating
+ * to a hardware implementation of the functionality of the software
+ * licensed hereunder.  You may use the software subject to the license
+ * terms below provided that you ensure that this notice is replicated
+ * unmodified and in its entirety in all distributions of the software,
+ * modified or unmodified, in source code or in binary form.
+ *
+ * Redistribution and use in source and binary forms, with or without
+ * modification, are permitted provided that the following conditions are
+ * met: redistributions of source code must retain the above copyright
+ * notice, this list of conditions and the following disclaimer;
+ * redistributions in binary form must reproduce the above copyright
+ * notice, this list of conditions and the following disclaimer in the
+ * documentation and/or other materials provided with the distribution;
+ * neither the name of the copyright holders nor the names of its
+ * contributors may be used to endorse or promote products derived from
+ * this software without specific prior written permission.
+ *
+ * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
+ * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
+ * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
+ * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
+ * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
+ * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
+ * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
+ * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
+ * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
+ * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
+ * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
+ *
+ * Authors: Gabor Dozsa
+ */
+
+/* @file
+ * Device module for a full duplex ethernet link for dist gem5 simulations.
+ *
+ * See comments in dev/dist_iface.hh for a generic description of dist
+ * gem5 simulations.
+ *
+ * This class is meant to be a drop in replacement for the EtherLink class for
+ * dist gem5 runs.
+ *
+ */
+#ifndef __DEV_MULTIETHERLINK_HH__
+#define __DEV_MULTIETHERLINK_HH__
+
+#include <iostream>
+
+#include "dev/etherlink.hh"
+#include "params/DistEtherLink.hh"
+
+class DistIface;
+class EthPacketData;
+
+/**
+ * Model for a fixed bandwidth full duplex ethernet link.
+ */
+class DistEtherLink : public EtherObject
+{
+  protected:
+    class LocalIface;
+
+    /**
+     * Model base class for a single uni-directional link.
+     *
+     * The link will encapsulate and transfer Ethernet packets to/from
+     * the message server.
+     */
+    class Link : public Serializable
+    {
+      protected:
+        std::string objName;
+        DistEtherLink *parent;
+        LocalIface *localIface;
+        EtherDump *dump;
+        DistIface *distIface;
+        Event *event;
+        EthPacketPtr packet;
+
+      public:
+        Link(const std::string &name, DistEtherLink *p,
+             EtherDump *d, Event *e) :
+            objName(name), parent(p), localIface(nullptr), dump(d),
+            distIface(nullptr), event(e) {}
+
+        ~Link() {}
+
+        const std::string name() const { return objName; }
+        bool busy() const { return (bool)packet; }
+        void setLocalInt(LocalIface *i) { assert(!localIface); localIface=i; }
+
+        void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
+        void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
+    };
+
+    /**
+     * Model for a send link.
+     */
+    class TxLink : public Link
+    {
+      protected:
+        /**
+         * Per byte send delay
+         */
+        double ticksPerByte;
+        /**
+         * Random component of the send delay
+         */
+        Tick delayVar;
+
+        /**
+         * Send done callback. Called from doneEvent.
+         */
+        void txDone();
+        typedef EventWrapper<TxLink, &TxLink::txDone> DoneEvent;
+        friend void DoneEvent::process();
+        DoneEvent doneEvent;
+
+      public:
+        TxLink(const std::string &name, DistEtherLink *p,
+               double invBW, Tick delay_var, EtherDump *d) :
+            Link(name, p, d, &doneEvent), ticksPerByte(invBW),
+            delayVar(delay_var), doneEvent(this) {}
+        ~TxLink() {}
+
+        /**
+         * Register the dist interface to be used to talk to the
+         * peer gem5 processes.
+         */
+        void setDistInt(DistIface *m) { assert(!distIface); distIface=m; }
+
+        /**
+         * Initiate sending of a packet via this link.
+         *
+         * @param packet Ethernet packet to send
+         */
+        bool transmit(EthPacketPtr packet);
+    };
+
+    /**
+     * Model for a receive link.
+     */
+    class RxLink : public Link
+    {
+      protected:
+
+        /**
+         * Transmission delay for the simulated Ethernet link.
+         */
+        Tick linkDelay;
+
+        /**
+         * Receive done callback method. Called from doneEvent.
+         */
+        void rxDone() ;
+        typedef EventWrapper<RxLink, &RxLink::rxDone> DoneEvent;
+        friend void DoneEvent::process();
+        DoneEvent doneEvent;
+
+      public:
+
+        RxLink(const std::string &name, DistEtherLink *p,
+               Tick delay, EtherDump *d) :
+            Link(name, p, d, &doneEvent),
+            linkDelay(delay), doneEvent(this) {}
+        ~RxLink() {}
+
+        /**
+         * Register our dist interface to talk to the peer gem5 processes.
+         */
+        void setDistInt(DistIface *m);
+    };
+
+    /**
+     * Interface to the local simulated system
+     */
+    class LocalIface : public EtherInt
+    {
+      private:
+        TxLink *txLink;
+
+      public:
+        LocalIface(const std::string &name, TxLink *tx, RxLink *rx,
+                   DistIface *m);
+
+        bool recvPacket(EthPacketPtr pkt) { return txLink->transmit(pkt); }
+        void sendDone() { peer->sendDone(); }
+        bool isBusy() { return txLink->busy(); }
+    };
+
+
+  protected:
+    /**
+     * Interface to talk to the peer gem5 processes.
+     */
+    DistIface *distIface;
+    /**
+     * Send link
+     */
+    TxLink *txLink;
+    /**
+     * Receive link
+     */
+    RxLink *rxLink;
+    LocalIface *localIface;
+
+  public:
+    typedef DistEtherLinkParams Params;
+    DistEtherLink(const Params *p);
+    ~DistEtherLink();
+
+    const Params *
+    params() const
+    {
+        return dynamic_cast<const Params *>(_params);
+    }
+
+    virtual EtherInt *getEthPort(const std::string &if_name,
+                                 int idx) M5_ATTR_OVERRIDE;
+
+    virtual void init() M5_ATTR_OVERRIDE;
+    virtual void startup() M5_ATTR_OVERRIDE;
+
+    void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
+    void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
+};
+
+#endif // __DEV_MULTIETHERLINK_HH__
diff --git a/src/dev/dist_iface.cc b/src/dev/dist_iface.cc
new file mode 100644
--- /dev/null
+++ b/src/dev/dist_iface.cc
@@ -0,0 +1,760 @@
+/*
+ * Copyright (c) 2015 ARM Limited
+ * All rights reserved
+ *
+ * The license below extends only to copyright in the software and shall
+ * not be construed as granting a license to any other intellectual
+ * property including but not limited to intellectual property relating
+ * to a hardware implementation of the functionality of the software
+ * licensed hereunder.  You may use the software subject to the license
+ * terms below provided that you ensure that this notice is replicated
+ * unmodified and in its entirety in all distributions of the software,
+ * modified or unmodified, in source code or in binary form.
+ *
+ * Redistribution and use in source and binary forms, with or without
+ * modification, are permitted provided that the following conditions are
+ * met: redistributions of source code must retain the above copyright
+ * notice, this list of conditions and the following disclaimer;
+ * redistributions in binary form must reproduce the above copyright
+ * notice, this list of conditions and the following disclaimer in the
+ * documentation and/or other materials provided with the distribution;
+ * neither the name of the copyright holders nor the names of its
+ * contributors may be used to endorse or promote products derived from
+ * this software without specific prior written permission.
+ *
+ * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
+ * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
+ * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
+ * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
+ * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
+ * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
+ * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
+ * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
+ * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
+ * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
+ * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
+ *
+ * Authors: Gabor Dozsa
+ */
+
+/* @file
+ * The interface class for dist-gem5 simulations.
+ */
+
+#include "dev/dist_iface.hh"
+
+#include <queue>
+#include <thread>
+
+#include "base/random.hh"
+#include "base/trace.hh"
+#include "debug/DistEthernet.hh"
+#include "debug/DistEthernetPkt.hh"
+#include "dev/etherpkt.hh"
+#include "sim/sim_exit.hh"
+#include "sim/sim_object.hh"
+
+using namespace std;
+DistIface::Sync *DistIface::sync = nullptr;
+DistIface::SyncEvent *DistIface::syncEvent = nullptr;
+unsigned DistIface::recvThreadsNum = 0;
+DistIface *DistIface::master = nullptr;
+
+void
+DistIface::Sync::init(Tick start_tick, Tick repeat_tick)
+{
+    if (start_tick < firstAt) {
+        firstAt = start_tick;
+        inform("Next dist synchronisation tick is changed to %lu.\n", nextAt);
+    }
+
+    if (repeat_tick == 0)
+        panic("Dist synchronisation interval must be greater than zero");
+
+    if (repeat_tick < nextRepeat) {
+        nextRepeat = repeat_tick;
+        inform("Dist synchronisation interval is changed to %lu.\n",
+               nextRepeat);
+    }
+}
+
+DistIface::SyncSwitch::SyncSwitch(int num_nodes)
+{
+    numNodes = num_nodes;
+    waitNum = num_nodes;
+    numExitReq = 0;
+    numCkptReq = 0;
+    doExit = false;
+    doCkpt = false;
+    firstAt = std::numeric_limits<Tick>::max();
+    nextAt = 0;
+    nextRepeat = std::numeric_limits<Tick>::max();
+}
+
+DistIface::SyncNode::SyncNode()
+{
+    waitNum = 0;
+    needExit = ReqType::none;
+    needCkpt = ReqType::none;
+    doExit = false;
+    doCkpt = false;
+    firstAt = std::numeric_limits<Tick>::max();
+    nextAt = 0;
+    nextRepeat = std::numeric_limits<Tick>::max();
+}
+
+void
+DistIface::SyncNode::run(bool same_tick)
+{
+    std::unique_lock<std::mutex> sync_lock(lock);
+    Header header;
+
+    assert(waitNum == 0);
+    waitNum = DistIface::recvThreadsNum;
+    // initiate the global synchronisation
+    header.msgType = MsgType::cmdSyncReq;
+    header.sendTick = curTick();
+    header.syncRepeat = nextRepeat;
+    header.needCkpt = needCkpt;
+    if (needCkpt != ReqType::none)
+        needCkpt = ReqType::pending;
+    header.needExit = needExit;
+    if (needCkpt != ReqType::none)
+        needCkpt = ReqType::pending;
+    DistIface::master->sendCmd(header);
+    // now wait until all receiver threads complete the synchronisation
+    auto lf = [this]{ return waitNum == 0; };
+    cv.wait(sync_lock, lf);
+    // global barrier is done
+    assert(!same_tick || (nextAt == curTick()));
+}
+
+
+void
+DistIface::SyncSwitch::run(bool same_tick)
+{
+    std::unique_lock<std::mutex> sync_lock(lock);
+    Header header;
+    if (waitNum > 0) {
+        auto lf = [this]{ return waitNum == 0; };
+        cv.wait(sync_lock, lf);
+    }
+    assert(waitNum == 0);
+    assert(!same_tick || (nextAt == curTick()));
+    waitNum = numNodes;
+    // initiate the global synchronisation
+    header.msgType = MsgType::cmdSyncAck;
+    //header.sendTick = curTick();
+    header.sendTick = nextAt;
+    header.syncRepeat = nextRepeat;
+    if (doCkpt || numCkptReq == numNodes) {
+        doCkpt = true;
+        header.needCkpt = ReqType::immediate;
+        numCkptReq = 0;
+    } else {
+        header.needCkpt = ReqType::none;
+    }
+    if (doExit || numExitReq == numNodes) {
+        doExit = true;
+        header.needExit = ReqType::immediate;
+    } else {
+        header.needExit = ReqType::none;
+    }
+    DistIface::master->sendCmd(header);
+}
+
+void
+DistIface::SyncSwitch::progress(Tick send_tick,
+                                 Tick sync_repeat,
+                                 ReqType need_ckpt,
+                                 ReqType need_exit)
+{
+    std::unique_lock<std::mutex> sync_lock(lock);
+    assert(waitNum > 0);
+
+    if (send_tick > nextAt)
+        nextAt = send_tick;
+    if (nextRepeat > sync_repeat)
+        nextRepeat = sync_repeat;
+
+    if (need_ckpt == ReqType::collective)
+        numCkptReq++;
+    if (need_ckpt == ReqType::immediate)
+        doCkpt = true;
+    if (need_exit == ReqType::collective)
+        numExitReq++;
+    if (need_exit == ReqType::immediate)
+        doExit = true;
+
+    waitNum--;
+    // Notify the simulation thread if the on-going sync is complete
+    if (waitNum == 0) {
+        sync_lock.unlock();
+        cv.notify_one();
+    }
+}
+
+void
+DistIface::SyncNode::progress(Tick max_send_tick,
+                               Tick next_repeat,
+                               ReqType do_ckpt,
+                               ReqType do_exit)
+{
+    std::unique_lock<std::mutex> sync_lock(lock);
+    assert(waitNum > 0);
+
+    nextAt = max_send_tick;
+    nextRepeat = next_repeat;
+    doCkpt = (do_ckpt != ReqType::none);
+    doExit = (do_exit != ReqType::none);
+
+    waitNum--;
+    // Notify the simulation thread if the on-going sync is complete
+    if (waitNum == 0) {
+        sync_lock.unlock();
+        cv.notify_one();
+    }
+}
+
+void
+DistIface::SyncNode::requestCkpt(ReqType req)
+{
+   std::lock_guard<std::mutex> sync_lock(lock);
+   assert(req != ReqType::none);
+   if (needCkpt != ReqType::none)
+       warn("Ckpt requested multiple times (req:%d)\n", static_cast<int>(req));
+   if (needCkpt == ReqType::none || req == ReqType::immediate)
+       needCkpt = req;
+}
+
+void
+DistIface::SyncNode::requestExit(ReqType req)
+{
+   std::lock_guard<std::mutex> sync_lock(lock);
+   assert(req != ReqType::none);
+   if (needExit != ReqType::none)
+       warn("Exit requested multiple times (req:%d)\n", static_cast<int>(req));
+   if (needExit == ReqType::none || req == ReqType::immediate)
+       needExit = req;
+}
+
+void
+DistIface::Sync::drainComplete()
+{
+    if (doCkpt) {
+        // The first DistIface object called this right before writing the
+        // checkpoint. We need to drain the underlying physical network here.
+        // Note that other gem5 peers may enter this barrier at different
+        // ticks due to draining.
+        run(false);
+        // Only the "first" DistIface object has to perform the sync
+        doCkpt = false;
+    }
+}
+
+void
+DistIface::SyncNode::serialize(CheckpointOut &cp) const
+{
+    int need_exit = static_cast<int>(needExit);
+    SERIALIZE_SCALAR(need_exit);
+}
+
+void
+DistIface::SyncNode::unserialize(CheckpointIn &cp)
+{
+    int need_exit;
+    UNSERIALIZE_SCALAR(need_exit);
+    needExit = static_cast<ReqType>(need_exit);
+}
+
+void
+DistIface::SyncSwitch::serialize(CheckpointOut &cp) const
+{
+    SERIALIZE_SCALAR(numExitReq);
+}
+
+void
+DistIface::SyncSwitch::unserialize(CheckpointIn &cp)
+{
+    UNSERIALIZE_SCALAR(numExitReq);
+}
+
+void
+DistIface::SyncEvent::start()
+{
+    // Note that this may be called either from startup() or drainResume()
+
+    // At this point, all DistIface objects has already called Sync::init() so
+    // we have a local minimum of the start tick and repeat for the periodic
+    // sync.
+    Tick firstAt  = DistIface::sync->firstAt;
+    repeat = DistIface::sync->nextRepeat;
+    // Do a global barrier to agree on a common repeat value (the smallest
+    // one from all participating nodes
+    DistIface::sync->run(curTick() == 0);
+
+    assert(!DistIface::sync->doCkpt);
+    assert(!DistIface::sync->doExit);
+    assert(DistIface::sync->nextAt >= curTick());
+    assert(DistIface::sync->nextRepeat <= repeat);
+
+    // if this is called at tick 0 then we use the config start param otherwise
+    // the maximum of the current tick of all participating nodes
+    if (curTick() == 0) {
+        assert(!scheduled());
+        assert(DistIface::sync->nextAt == 0);
+        schedule(firstAt);
+    } else {
+        if (scheduled())
+            reschedule(DistIface::sync->nextAt);
+        else
+            schedule(DistIface::sync->nextAt);
+    }
+    inform("Dist sync scheduled at %lu and repeats %lu\n",  when(),
+           DistIface::sync->nextRepeat);
+}
+
+void
+DistIface::SyncEvent::process()
+{
+    /*
+     * Note that this is a global event so this process method will be called
+     * by only exactly one thread.
+     */
+    /*
+     * We hold the eventq lock at this point but the receiver thread may
+     * need the lock to schedule new recv events while waiting for the
+     * dist sync to complete.
+     * Note that the other simulation threads also release their eventq
+     * locks while waiting for us due to the global event semantics.
+     */
+    {
+        EventQueue::ScopedRelease sr(curEventQueue());
+        // we do a global sync here that is supposed to happen at the same
+        // tick in all gem5 peers
+        DistIface::sync->run(true);
+        // global sync completed
+    }
+    if (DistIface::sync->doCkpt)
+        exitSimLoop("checkpoint");
+    if (DistIface::sync->doExit)
+        exitSimLoop("exit request from gem5 peers");
+
+    // schedule the next periodic sync
+    repeat = DistIface::sync->nextRepeat;
+    schedule(curTick() + repeat);
+}
+
+void
+DistIface::RecvScheduler::init(Event *recv_done, Tick link_delay)
+{
+    // This is called from the receiver thread when it starts running. The new
+    // receiver thread shares the event queue with the simulation thread
+    // (associated with the simulated Ethernet link).
+    curEventQueue(eventManager->eventQueue());
+
+    recvDone = recv_done;
+    linkDelay = link_delay;
+}
+
+Tick
+DistIface::RecvScheduler::calcReceiveTick(Tick send_tick,
+                                           Tick send_delay,
+                                           Tick prev_recv_tick)
+{
+    Tick recv_tick = send_tick + send_delay + linkDelay;
+    // sanity check (we need atleast a send delay long window)
+    assert(recv_tick >= prev_recv_tick + send_delay);
+    panic_if(prev_recv_tick + send_delay > recv_tick,
+             "Receive window is smaller than send delay");
+    panic_if(recv_tick <= curTick(),
+             "Simulators out of sync - missed packet receive by %llu ticks"
+             "(rev_recv_tick: %lu send_tick: %lu send_delay: %lu "
+             "linkDelay: %lu )",
+             curTick() - recv_tick, prev_recv_tick, send_tick, send_delay,
+             linkDelay);
+
+    return recv_tick;
+}
+
+void
+DistIface::RecvScheduler::resumeRecvTicks()
+{
+    // Schedule pending packets asap in case link speed/delay changed when
+    // resuming from the checkpoint.
+    // This may be done during unserialize except that curTick() is unknown.
+    std::vector<Desc> v;
+    while (!descQueue.empty()) {
+        Desc d = descQueue.front();
+        descQueue.pop();
+        d.sendTick = curTick();
+        d.sendDelay = d.packet->size(); // assume 1 tick/byte max link speed
+        v.push_back(d);
+    }
+
+    for (auto &d : v)
+        descQueue.push(d);
+
+    if (recvDone->scheduled()) {
+        assert(!descQueue.empty());
+        eventManager->reschedule(recvDone, curTick());
+    } else {
+        assert(descQueue.empty() && v.empty());
+    }
+}
+
+void
+DistIface::RecvScheduler::pushPacket(EthPacketPtr new_packet,
+                                      Tick send_tick,
+                                      Tick send_delay)
+{
+    // Note : this is called from the receiver thread
+    curEventQueue()->lock();
+    Tick recv_tick = calcReceiveTick(send_tick, send_delay, prevRecvTick);
+
+    DPRINTF(DistEthernetPkt, "DistIface::recvScheduler::pushPacket "
+            "send_tick:%llu send_delay:%llu link_delay:%llu recv_tick:%llu\n",
+            send_tick, send_delay, linkDelay, recv_tick);
+    // Every packet must be sent and arrive in the same quantum
+    assert(send_tick > master->syncEvent->when() -
+           master->syncEvent->repeat);
+    // No packet may be scheduled for receive in the arrivel quantum
+    assert(send_tick + send_delay + linkDelay > master->syncEvent->when());
+
+    // Now we are about to schedule a recvDone event for the new data packet.
+    // We use the same recvDone object for all incoming data packets. Packet
+    // descriptors are saved in the ordered queue. The currently scheduled
+    // packet is always on the top of the queue.
+    // NOTE:  we use the event queue lock to protect the receive desc queue,
+    // too, which is accessed both by the receiver thread and the simulation
+    // thread.
+    descQueue.emplace(new_packet, send_tick, send_delay);
+    if (descQueue.size() == 1) {
+        assert(!recvDone->scheduled());
+        eventManager->schedule(recvDone, recv_tick);
+    } else {
+        assert(recvDone->scheduled());
+        panic_if(descQueue.front().sendTick + descQueue.front().sendDelay > recv_tick,
+                 "Out of order packet received (recv_tick: %lu top(): %lu\n",
+                 recv_tick, descQueue.front().sendTick + descQueue.front().sendDelay);
+    }
+    curEventQueue()->unlock();
+}
+
+EthPacketPtr
+DistIface::RecvScheduler::popPacket()
+{
+    // Note : this is called from the simulation thread when a receive done
+    // event is being processed for the link. We assume that the thread holds
+    // the event queue queue lock when this is called!
+    EthPacketPtr next_packet = descQueue.front().packet;
+    descQueue.pop();
+
+    if (descQueue.size() > 0) {
+        Tick recv_tick = calcReceiveTick(descQueue.front().sendTick,
+                                         descQueue.front().sendDelay,
+                                         curTick());
+        eventManager->schedule(recvDone, recv_tick);
+    }
+    prevRecvTick = curTick();
+    return next_packet;
+}
+
+void
+DistIface::RecvScheduler::Desc::serialize(CheckpointOut &cp) const
+{
+        SERIALIZE_SCALAR(sendTick);
+        SERIALIZE_SCALAR(sendDelay);
+        packet->serialize("rxPacket", cp);
+}
+
+void
+DistIface::RecvScheduler::Desc::unserialize(CheckpointIn &cp)
+{
+        UNSERIALIZE_SCALAR(sendTick);
+        UNSERIALIZE_SCALAR(sendDelay);
+        packet = std::make_shared<EthPacketData>(16384);
+        packet->unserialize("rxPacket", cp);
+}
+
+void
+DistIface::RecvScheduler::serialize(CheckpointOut &cp) const
+{
+    SERIALIZE_SCALAR(prevRecvTick);
+    // serialize the receive desc queue
+    std::queue<Desc> tmp_queue(descQueue);
+    unsigned n_desc_queue = descQueue.size();
+    assert(tmp_queue.size() == descQueue.size());
+    SERIALIZE_SCALAR(n_desc_queue);
+    for (int i = 0; i < n_desc_queue; i++) {
+        tmp_queue.front().serializeSection(cp, csprintf("rxDesc_%d", i));
+        tmp_queue.pop();
+    }
+    assert(tmp_queue.empty());
+}
+
+void
+DistIface::RecvScheduler::unserialize(CheckpointIn &cp)
+{
+    assert(descQueue.size() == 0);
+    assert(recvDone->scheduled() == false);
+
+    UNSERIALIZE_SCALAR(prevRecvTick);
+    // unserialize the receive desc queue
+    unsigned n_desc_queue;
+    UNSERIALIZE_SCALAR(n_desc_queue);
+    for (int i = 0; i < n_desc_queue; i++) {
+        Desc recv_desc;
+        recv_desc.unserializeSection(cp, csprintf("rxDesc_%d", i));
+        descQueue.push(recv_desc);
+    }
+}
+
+DistIface::DistIface(unsigned dist_rank,
+                       unsigned dist_size,
+                       Tick sync_start,
+                       Tick sync_repeat,
+                       EventManager *em,
+                       bool is_switch, int num_nodes) :
+    syncStart(sync_start), syncRepeat(sync_repeat),
+    recvThread(nullptr), recvScheduler(em),
+    rank(dist_rank), size(dist_size)
+{
+    DPRINTF(DistEthernet, "DistIface() ctor rank:%d\n",dist_rank);
+    isMaster = false;
+    if (master == nullptr) {
+        assert(sync == nullptr);
+        assert(syncEvent == nullptr);
+        if (is_switch)
+            sync = new SyncSwitch(num_nodes);
+        else
+            sync = new SyncNode();
+        syncEvent = new SyncEvent();
+        master = this;
+        isMaster = true;
+    }
+}
+
+DistIface::~DistIface()
+{
+    assert(recvThread);
+    delete recvThread;
+    if (this == master) {
+        assert(syncEvent);
+        delete syncEvent;
+        assert(sync);
+        delete sync;
+        master = nullptr;
+    }
+}
+
+void
+DistIface::packetOut(EthPacketPtr pkt, Tick send_delay)
+{
+    Header header;
+
+    // Prepare a dist header packet for the Ethernet packet we want to
+    // send out.
+    header.msgType = MsgType::dataDescriptor;
+    header.sendTick  = curTick();
+    header.sendDelay = send_delay;
+
+    header.dataPacketLength = pkt->size();
+
+    // Send out the packet and the meta info.
+    sendPacket(header, pkt);
+
+    DPRINTF(DistEthernetPkt,
+            "DistIface::sendDataPacket() done size:%d send_delay:%llu\n",
+            pkt->size(), send_delay);
+}
+
+void
+DistIface::recvThreadFunc(Event *recv_done, Tick link_delay)
+{
+    EthPacketPtr new_packet;
+    DistHeaderPkt::Header header;
+
+    // Initialize receive scheduler parameters
+    recvScheduler.init(recv_done, link_delay);
+
+    // Main loop to wait for and process any incoming message.
+    for (;;) {
+        // recvHeader() blocks until the next dist header packet comes in.
+        if (!recvHeader(header)) {
+            // We lost connection to the peer gem5 processes most likely
+            // because one of them called m5 exit. So we stop here.
+            // Grab the eventq lock to stop the simulation thread
+            curEventQueue()->lock();
+            exit_message("info",
+                         0,
+                         "Message server closed connection, "
+                         "simulation is exiting");
+        }
+
+        // We got a valid dist header packet, let's process it
+        if (header.msgType == MsgType::dataDescriptor) {
+            recvPacket(header, new_packet);
+            recvScheduler.pushPacket(new_packet,
+                                     header.sendTick,
+                                     header.sendDelay);
+        } else {
+            // everything else must be synchronisation related command
+            sync->progress(header.sendTick,
+                           header.syncRepeat,
+                           header.needCkpt,
+                           header.needExit);
+        }
+    }
+}
+
+void
+DistIface::spawnRecvThread(Event *recv_done, Tick link_delay)
+{
+    assert(recvThread == nullptr);
+
+    recvThread = new std::thread(&DistIface::recvThreadFunc,
+                                 this,
+                                 recv_done,
+                                 link_delay);
+    recvThreadsNum++;
+}
+
+DrainState
+DistIface::drain()
+{
+    DPRINTF(DistEthernet,"DistIFace::drain() called\n");
+
+    // This can be called multiple times in the same drain cycle.
+    return DrainState::Drained;
+}
+
+void
+DistIface::drainResume() {
+    if (master == this) {
+        syncEvent->start();
+    }
+    recvScheduler.resumeRecvTicks();
+}
+
+void
+DistIface::serialize(CheckpointOut &cp) const
+{
+    // Drain the dist interface before the checkpoint is taken. We cannot call
+    // this as part of the normal drain cycle because this dist sync has to be
+    // called exactly once after the system is fully drained.
+    sync->drainComplete();
+
+    recvScheduler.serializeSection(cp, "recvScheduler");
+    if (this == master) {
+        sync->serializeSection(cp, "Sync");
+    }
+}
+
+void
+DistIface::unserialize(CheckpointIn &cp)
+{
+    recvScheduler.unserializeSection(cp, "recvScheduler");
+    if (this == master) {
+        sync->unserializeSection(cp, "Sync");
+  }
+}
+
+void
+DistIface::init()
+{
+    // Adjust the periodic sync start and interval. Different DistIface
+    // might have different requirements. The singleton sync object
+    // will select the minimum values for both params.
+    assert(sync != nullptr);
+    sync->init(syncStart, syncRepeat);
+
+    // Initialize the seed for random generator to avoid the same sequence
+    // in all gem5 peer processes
+    assert(master != nullptr);
+    if (this == master)
+        random_mt.init(5489 * (rank+1) + 257);
+}
+
+void
+DistIface::startup()
+{
+    DPRINTF(DistEthernet, "DistIface::startup() started\n");
+    // If this run is a resume from a checkpoint than we schedule the first
+    // periodic sync in drainResume()
+    if (curTick() == 0 && this == master)
+        syncEvent->start();
+
+    DPRINTF(DistEthernet, "DistIface::startup() done\n");
+}
+
+bool
+DistIface::readyToCkpt(Tick delay, Tick period)
+{
+    bool ret = true;
+    DPRINTF(DistEthernet, "DistIface::readyToCkpt() called, delay:%lu "
+            "period:%lu\n", delay, period);
+    if (master) {
+        if (delay == 0) {
+            inform("m5 checkpoint called with zero delay => triggering collaborative "
+                   "checkpoint\n");
+            sync->requestCkpt(ReqType::collective);
+        } else {
+            inform("m5 checkpoint called with non-zero delay => triggering immediate "
+                   "checkpoint (at the next sync)\n");
+            sync->requestCkpt(ReqType::immediate);
+        }
+        if (period != 0)
+            inform("Non-zero period for m5_ckpt is ignored in "
+                   "distributed gem5 runs\n");
+        ret = false;
+    }
+    return ret;
+}
+
+bool
+DistIface::readyToExit(Tick delay)
+{
+    bool ret = true;
+    DPRINTF(DistEthernet, "DistIface::readyToExit() called, delay:%lu\n",
+            delay);
+    if (master) {
+        if (delay == 0) {
+            inform("m5 exit called with zero delay => triggering collaborative "
+                   "exit\n");
+            sync->requestExit(ReqType::collective);
+        } else {
+            inform("m5 exit called with non-zero delay => triggering immediate "
+                   "exit (at the next sync)\n");
+            sync->requestExit(ReqType::immediate);
+        }
+        ret = false;
+    }
+    return ret;
+}
+
+uint64_t
+DistIface::rankParam()
+{
+    uint64_t val;
+    if (master) {
+        val = master->rank;
+    } else {
+        warn("Dist-rank parameter is queried in single gem5 simulation.");
+        val = 0;
+    }
+    return val;
+}
+
+uint64_t
+DistIface::sizeParam()
+{
+    uint64_t val;
+    if (master) {
+        val = master->size;
+    } else {
+        warn("Dist-size parameter is queried in single gem5 simulation.");
+        val = 1;
+    }
+    return val;
+}
diff --git a/src/dev/dist_iface.hh b/src/dev/dist_iface.hh
new file mode 100644
--- /dev/null
+++ b/src/dev/dist_iface.hh
@@ -0,0 +1,564 @@
+/*
+ * Copyright (c) 2015 ARM Limited
+ * All rights reserved
+ *
+ * The license below extends only to copyright in the software and shall
+ * not be construed as granting a license to any other intellectual
+ * property including but not limited to intellectual property relating
+ * to a hardware implementation of the functionality of the software
+ * licensed hereunder.  You may use the software subject to the license
+ * terms below provided that you ensure that this notice is replicated
+ * unmodified and in its entirety in all distributions of the software,
+ * modified or unmodified, in source code or in binary form.
+ *
+ * Redistribution and use in source and binary forms, with or without
+ * modification, are permitted provided that the following conditions are
+ * met: redistributions of source code must retain the above copyright
+ * notice, this list of conditions and the following disclaimer;
+ * redistributions in binary form must reproduce the above copyright
+ * notice, this list of conditions and the following disclaimer in the
+ * documentation and/or other materials provided with the distribution;
+ * neither the name of the copyright holders nor the names of its
+ * contributors may be used to endorse or promote products derived from
+ * this software without specific prior written permission.
+ *
+ * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
+ * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
+ * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
+ * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
+ * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
+ * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
+ * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
+ * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
+ * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
+ * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
+ * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
+ *
+ * Authors: Gabor Dozsa
+ */
+
+/* @file
+ * The interface class for dist gem5 simulations.
+ *
+ * dist-gem5 is an extension to gem5 to enable parallel simulation of a
+ * distributed system (e.g. simulation of a pool of machines
+ * connected by Ethernet links). A dist gem5 run consists of seperate gem5
+ * processes running in parallel. Each gem5 process executes
+ * the simulation of a component of the simulated distributed system.
+ * (An example component can be a dist-core board with an Ethernet NIC.)
+ * The DistIface class below provides services to transfer data and
+ * control messages among the gem5 processes. The main such services are
+ * as follows.
+ *
+ * 1. Send a data packet coming from a simulated Ethernet link. The packet
+ * will be transferred to (all) the target(s) gem5 processes. The send
+ * operation is always performed by the simulation thread, i.e. the gem5
+ * thread that is processing the event queue associated with the simulated
+ * Ethernet link.
+ *
+ * 2. Spawn a receiver thread to process messages coming in from the
+ * from other gem5 processes. Each simulated Ethernet link has its own
+ * associated receiver thread. The receiver thread saves the incoming packet
+ * and schedule an appropriate receive event in the event queue.
+ *
+ * 3. Schedule a global barrier event periodically to keep the gem5
+ * processes in sync.
+ * Periodic barrier event to keep peer gem5 processes in sync. The basic idea
+ * is that no gem5 process can go ahead further than the simulated link
+ * transmission delay to ensure that a corresponding receive event can always
+ * be scheduled for any message coming in from a peer gem5 process.
+ *
+ *
+ *
+ * This interface is an abstract class (sendRaw() and recvRaw()
+ * methods are pure virtual). It can work with various low level
+ * send/receive service implementations (e.g. TCP/IP, MPI,...). A TCP
+ * stream socket version is implemented in dev/src/tcp_iface.[hh,cc].
+ */
+#ifndef __DEV_MULTI_IFACE_HH__
+#define __DEV_MULTI_IFACE_HH__
+
+#include <array>
+#include <mutex>
+#include <queue>
+#include <thread>
+#include <utility>
+
+#include "dev/dist_packet.hh"
+#include "dev/etherpkt.hh"
+#include "sim/core.hh"
+#include "sim/drain.hh"
+#include "sim/global_event.hh"
+#include "sim/serialize.hh"
+
+class EventManager;
+
+/**
+ * The interface class to talk to peer gem5 processes.
+ */
+class DistIface : public Drainable, public Serializable
+{
+  public:
+    typedef DistHeaderPkt::Header Header;
+
+  protected:
+    typedef DistHeaderPkt::MsgType MsgType;
+    typedef DistHeaderPkt::ReqType ReqType;
+
+  private:
+    class SyncEvent;
+    /** @class Sync
+     * This class implements global sync operations among gem5 peer processes.
+     *
+     * @note This class is used as a singleton object (shared by all DistIface
+     * objects).
+     */
+    class Sync : public Serializable
+    {
+      protected:
+        /**
+         * The lock to protect access to the Sync object.
+         */
+        std::mutex lock;
+        /**
+         * Condition variable for the simulation thread to wait on
+         * until all receiver threads completes the current global
+         * synchronisation.
+         */
+        std::condition_variable cv;
+        /**
+         * Number of receiver threads that not yet completed the current global
+         * synchronisation.
+         */
+        unsigned waitNum;
+        /**
+         * Flag is set if exit is permitted upon sync completion
+         */
+        bool doExit;
+        /**
+         * Flag is set if taking a ckpt is permitted upon sync completion
+         */
+        bool doCkpt;
+        /**
+         * The repeat value for the next periodic sync
+         */
+        Tick nextRepeat;
+        /**
+         * Tick for the very first periodic sync
+         */
+        Tick firstAt;
+        /**
+         * Tick for the next periodic sync (if the event is not scheduled yet)
+         */
+        Tick nextAt;
+
+        friend class SyncEvent;
+
+      public:
+        /**
+         * Initialize periodic sync params.
+         *
+         * @param start Start tick for dist synchronisation
+         * @param repeat Frequency of dist synchronisation
+         *
+         */
+        void init(Tick start, Tick repeat);
+        /**
+         *  Core method to perform a full dist sync.
+         */
+        virtual void run(bool same_tick) = 0;
+        /**
+         * Callback when the receiver thread gets a sync ack message.
+         */
+        virtual void progress(Tick send_tick,
+                              Tick next_repeat,
+                              ReqType do_ckpt,
+                              ReqType do_exit) = 0;
+
+        virtual void requestCkpt(ReqType req) = 0;
+        virtual void requestExit(ReqType req) = 0;
+
+        void drainComplete();
+
+        virtual void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE = 0;
+        virtual void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE = 0;
+    };
+
+    class SyncNode: public Sync
+    {
+      private:
+        /**
+         * Exit requested
+         */
+        ReqType needExit;
+        /**
+         * Ckpt requested
+         */
+        ReqType needCkpt;
+
+      public:
+
+        SyncNode();
+        ~SyncNode() {}
+        void run(bool same_tick) M5_ATTR_OVERRIDE;
+        void progress(Tick max_req_tick,
+                      Tick next_repeat,
+                      ReqType do_ckpt,
+                      ReqType do_exit) M5_ATTR_OVERRIDE;
+
+        void requestCkpt(ReqType req) M5_ATTR_OVERRIDE;
+        void requestExit(ReqType req) M5_ATTR_OVERRIDE;
+
+        void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
+        void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
+    };
+
+    class SyncSwitch: public Sync
+    {
+      private:
+        /**
+         * Counter for recording exit requests
+         */
+        unsigned numExitReq;
+        /**
+         * Counter for recording ckpt requests
+         */
+        unsigned numCkptReq;
+        /**
+         *  Number of connected simulated nodes
+         */
+        unsigned numNodes;
+
+      public:
+        SyncSwitch(int num_nodes);
+        ~SyncSwitch() {}
+
+        void run(bool same_tick) M5_ATTR_OVERRIDE;
+        void progress(Tick max_req_tick,
+                      Tick next_repeat,
+                      ReqType do_ckpt,
+                      ReqType do_exit) M5_ATTR_OVERRIDE;
+
+        void requestCkpt(ReqType) M5_ATTR_OVERRIDE {
+            panic("Switch requested checkpoint");
+        }
+        void requestExit(ReqType) M5_ATTR_OVERRIDE {
+            panic("Switch requested exit");
+        }
+
+        void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
+        void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
+    };
+
+    /**
+     * The global event to schedule peridic dist sync. It is used as a
+     * singleton object.
+     *
+     * The periodic synchronisation works as follows.
+     * 1. A DistsyncEvent is scheduled as a global event when startup() is
+     * called.
+     * 2. The progress() method of the DistsyncEvent initiates a new barrier
+     * for each simulated Ethernet links.
+     * 3. Simulation thread(s) then waits until all receiver threads
+     * completes the ongoing barrier. The global sync event is done.
+     */
+    class SyncEvent : public GlobalSyncEvent
+    {
+      public:
+        /**
+         * Only the firstly instantiated DistIface object will
+         * call this constructor.
+         */
+        SyncEvent() : GlobalSyncEvent(Sim_Exit_Pri, 0) {}
+
+        ~SyncEvent() {}
+        /**
+         * Schedule the first periodic sync event.
+         */
+        void start();
+        /**
+         * This is a global event so process() will be called by each
+         * simulation threads. (See further comments in the .cc file.)
+         */
+        void process() M5_ATTR_OVERRIDE;
+    };
+    /**
+     * Class to encapsulate information about data packets received.
+
+     * @note The main purpose of the class to take care of scheduling receive
+     * done events for the simulated network link and store incoming packets
+     * until they can be received by the simulated network link.
+     */
+    class RecvScheduler : public Serializable
+    {
+      private:
+        /**
+         * Received packet descriptor. This information is used by the receive
+         * thread to schedule receive events and by the simulation thread to
+         * process those events.
+         */
+        struct Desc : public Serializable {
+            EthPacketPtr packet;
+            Tick sendTick;
+            Tick sendDelay;
+
+            Desc() : sendTick(0), sendDelay(0) {}
+            Desc(EthPacketPtr p, Tick s, Tick d) :
+                packet(p), sendTick(s), sendDelay(d) {}
+            Desc(const Desc &d) :
+                packet(d.packet), sendTick(d.sendTick), sendDelay(d.sendDelay) {}
+
+            void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
+            void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
+        };
+        /**
+         * The queue to store the receive descriptors.
+         */
+        std::queue<Desc> descQueue;
+        /**
+         * The tick when the most recent receive event was processed.
+         *
+         * @note This information is necessary to simulate possible receiver
+         * link contention when calculating the receive tick for the next
+         * incoming data packet (see the calcReceiveTick() method)
+         */
+        Tick prevRecvTick;
+        /**
+         * The receive done event for the simulated Ethernet link.
+         *
+         * @note This object is constructed by the simulated network link. We
+         * schedule this object for each incoming data packet.
+         */
+        Event *recvDone;
+        /**
+         * The link delay in ticks for the simulated Ethernet link.
+         *
+         * @note This value is used for calculating the receive ticks for an
+         * incoming data packets.
+         */
+        Tick linkDelay;
+        /**
+         * The event manager associated with the simulated Ethernet link.
+         *
+         * @note It is used to access the event queue for scheduling receive
+         * done events for the link.
+         */
+        EventManager *eventManager;
+        /**
+         * Calculate the tick to schedule the next receive done event.
+         *
+         * @param send_tick The tick the packet was sent.
+         * @param send_delay The simulated delay at the sender side.
+         * @param prev_recv_tick Tick when the last receive event was
+         * processed.
+         *
+         * @note This method tries to take into account possible receiver link
+         * contention and adjust receive tick for the incoming packets
+         * accordingly.
+         */
+        Tick calcReceiveTick(Tick send_tick,
+                             Tick send_delay,
+                             Tick prev_recv_tick);
+
+
+      public:
+        /**
+         * Scheduler for the incoming data packets.
+         *
+         * @param em The event manager associated with the simulated Ethernet
+         * link.
+         */
+        RecvScheduler(EventManager *em) :
+            prevRecvTick(0), recvDone(nullptr), linkDelay(0),
+            eventManager(em) {}
+
+        /**
+         *  Initialize network link parameters.
+         *
+         * @note This method is called from the receiver thread (see
+         * recvThreadFunc()).
+         */
+        void init(Event *recv_done, Tick link_delay);
+        /**
+         * Fetch the next packet that is to be received by the simulated network
+         * link.
+         *
+         * @note This method is called from the process() method of the receive
+         * done event associated with the network link.
+         */
+        EthPacketPtr popPacket();
+        /**
+         * Push a newly arrived packet into the desc queue.
+         */
+        void pushPacket(EthPacketPtr new_packet,
+                        Tick send_tick,
+                        Tick send_delay);
+
+        void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
+        void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
+        /**
+         * Adjust receive ticks for pending packets when resuming from a
+         * checkpoint
+         *
+         * @note Link speed and delay parameters may change at resume.
+         */
+        void resumeRecvTicks();
+  };
+    /**
+     * Tick to schedule the first dist sync event.
+     * This is just as optimization : we do not need any dist sync
+     * event until the simulated NIC is brought up by the OS.
+     */
+    Tick syncStart;
+    /**
+     * Frequency of dist sync events in ticks.
+     */
+    Tick syncRepeat;
+    /**
+     * Receiver thread pointer.
+     * Each DistIface object must have exactly one receiver thread.
+     */
+    std::thread *recvThread;
+    /**
+     * Meta information about data packets received.
+     */
+    RecvScheduler recvScheduler;
+
+  protected:
+    /**
+     * The rank of this process among the gem5 peers.
+     */
+    unsigned rank;
+    /**
+     * The number of gem5 processes comprising this dist simulation.
+     */
+    unsigned size;
+
+    bool isMaster;
+
+  private:
+    /**
+     * Total number of receiver threads (in this gem5 process).
+     * During the simulation it should be constant and equal to the
+     * number of DistIface objects (i.e. simulated Ethernet
+     * links).
+     */
+    static unsigned recvThreadsNum;
+    /**
+     * The singleton Sync object to perform dist synchronisation.
+     */
+    static Sync *sync;
+    /**
+     * The singleton SyncEvent object to schedule periodic dist sync.
+     */
+    static SyncEvent *syncEvent;
+    /**
+     * The very first DistIface object created becomes the master. We need
+     * a master to co-ordinate the global synchronisation.
+     */
+    static DistIface *master;
+
+  private:
+    /**
+     * Send out a data packet to the remote end.
+     * @param header Meta info about the packet (which needs to be transferred
+     * to the destination alongside the packet).
+     * @param packet Pointer to the packet to send.
+     */
+    virtual void sendPacket(const Header &header, const EthPacketPtr &packet) = 0;
+    /**
+     * Send out a control command to the remote end.
+     * @param header Meta info describing the command (e.g. sync request)
+     */
+    virtual void sendCmd(const Header &header) = 0;
+    /**
+     * Receive a header (i.e. meta info describing a data packet or a control command)
+     * from the remote end.
+     * @param header The meta info structure to store the incoming header.
+     */
+    virtual bool recvHeader(Header &header) = 0;
+    /**
+     * Receive a packet from the remote end.
+     * @param header Meta info about the incoming packet (obtanied by a previous
+     * call to the recvHedaer() method).
+     * @param Pointer to packet received.
+     */
+    virtual void recvPacket(const Header &header, EthPacketPtr &packet) = 0;
+    /**
+     * The function executed by a receiver thread.
+     */
+    void recvThreadFunc(Event *recv_done, Tick link_delay);
+
+  public:
+
+    /**
+     * ctor
+     * @param dist_rank Rank of this gem5 process within the dist run
+     * @param sync_start Start tick for dist synchronisation
+     * @param sync_repeat Frequency for dist synchronisation
+     * @param em The event manager associated with the simulated Ethernet link
+     */
+    DistIface(unsigned dist_rank,
+               unsigned dist_size,
+               Tick sync_start,
+               Tick sync_repeat,
+               EventManager *em,
+               bool is_switch,
+               int num_nodes);
+
+    virtual ~DistIface();
+    /**
+     * Send out an Ethernet packet.
+     * @param pkt The Ethernet packet to send.
+     * @param send_delay The delay in ticks for the send completion event.
+     */
+    void packetOut(EthPacketPtr pkt, Tick send_delay);
+    /**
+     * Fetch the packet scheduled to be received next by the simulated
+     * network link.
+     *
+     * @note This method is called within the process() method of the link
+     * receive done event. It also schedules the next receive event if the
+     * receive queue is not empty.
+     */
+    EthPacketPtr packetIn() { return recvScheduler.popPacket(); }
+    /**
+     * spawn the receiver thread.
+     * @param recv_done The receive done event associated with the simulated
+     * Ethernet link.
+     * @param link_delay The link delay for the simulated Ethernet link.
+     */
+    void spawnRecvThread(Event *recv_done, Tick link_delay);
+
+    DrainState drain() M5_ATTR_OVERRIDE;
+    void drainResume() M5_ATTR_OVERRIDE;
+    void init();
+    void startup();
+
+    void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
+    void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
+    /**
+     * Initiate the exit from the simulation.
+     *
+     * @return False if we are in dist mode and a collaborative exit is
+     * initiated, True otherwise.
+     */
+    static bool readyToExit(Tick delay);
+    /**
+     * Initiate taking a checkpoint
+     *
+     * @return False if we are in dist mode and a collaborative checkpoint is
+     * initiated, True otherwise.
+     */
+    static bool readyToCkpt(Tick delay, Tick period);
+    /**
+     * Getter for the dist rank param.
+     */
+    static uint64_t rankParam();
+    /**
+     * Getter for the dist size param.
+     */
+    static uint64_t sizeParam();
+ };
+
+#endif
diff --git a/src/dev/dist_packet.hh b/src/dev/dist_packet.hh
new file mode 100644
--- /dev/null
+++ b/src/dev/dist_packet.hh
@@ -0,0 +1,106 @@
+/*
+ * Copyright (c) 2015 ARM Limited
+ * All rights reserved
+ *
+ * The license below extends only to copyright in the software and shall
+ * not be construed as granting a license to any other intellectual
+ * property including but not limited to intellectual property relating
+ * to a hardware implementation of the functionality of the software
+ * licensed hereunder.  You may use the software subject to the license
+ * terms below provided that you ensure that this notice is replicated
+ * unmodified and in its entirety in all distributions of the software,
+ * modified or unmodified, in source code or in binary form.
+ *
+ * Redistribution and use in source and binary forms, with or without
+ * modification, are permitted provided that the following conditions are
+ * met: redistributions of source code must retain the above copyright
+ * notice, this list of conditions and the following disclaimer;
+ * redistributions in binary form must reproduce the above copyright
+ * notice, this list of conditions and the following disclaimer in the
+ * documentation and/or other materials provided with the distribution;
+ * neither the name of the copyright holders nor the names of its
+ * contributors may be used to endorse or promote products derived from
+ * this software without specific prior written permission.
+ *
+ * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
+ * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
+ * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
+ * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
+ * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
+ * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
+ * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
+ * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
+ * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
+ * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
+ * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
+ *
+ * Authors: Gabor Dozsa
+ */
+
+/* @file
+ * Header packet class for dist-gem5 runs.
+ *
+ * For a high level description about dist-gem5 see comments in
+ * header file dist_iface.hh.
+ *
+ * The DistHeaderPkt class defines the format of message headers
+ * sent among gem5 processes during a dist gem5 simulation. A header packet
+ * can either carry the description of data packet (i.e. a simulated Ethernet
+ * packet) or a synchronisation related control command. In case of
+ * data packet description, the corresponding data packet always follows
+ * the header packet back-to-back.
+ */
+#ifndef __DEV_DIST_PACKET_HH__
+#define __DEV_DIST_PACKET_HH__
+
+#include <cstring>
+
+#include "base/types.hh"
+
+class DistHeaderPkt
+{
+  private:
+    DistHeaderPkt() {}
+    ~DistHeaderPkt() {}
+
+  public:
+    enum class ReqType { immediate, collective, pending, none };
+    /**
+     *  The msg type defines what informarion a dist header packet carries.
+     */
+    enum class MsgType
+    {
+        dataDescriptor,
+        cmdSyncReq,
+        cmdSyncAck,
+        unknown
+    };
+
+    struct Header
+    {
+        /**
+         * The msg type field is valid for all header packets.
+         *
+         * @note senderRank is used with data packets while collFlags are used
+         * by sync ack messages to trigger collective ckpt or exit events.
+         */
+        MsgType msgType;
+        Tick sendTick;
+        union {
+            Tick sendDelay;
+            Tick syncRepeat;
+        };
+        union {
+            /**
+             * Actual length of the simulated Ethernet packet.
+             */
+            unsigned dataPacketLength;
+            struct {
+                ReqType needCkpt;
+                ReqType needExit;
+            };
+        };
+    };
+};
+
+#endif
diff --git a/src/dev/multi_etherlink.cc b/src/dev/multi_etherlink.cc
deleted file mode 100644
--- a/src/dev/multi_etherlink.cc
+++ /dev/null
@@ -1,272 +0,0 @@
-/*
- * Copyright (c) 2015 ARM Limited
- * All rights reserved
- *
- * The license below extends only to copyright in the software and shall
- * not be construed as granting a license to any other intellectual
- * property including but not limited to intellectual property relating
- * to a hardware implementation of the functionality of the software
- * licensed hereunder.  You may use the software subject to the license
- * terms below provided that you ensure that this notice is replicated
- * unmodified and in its entirety in all distributions of the software,
- * modified or unmodified, in source code or in binary form.
- *
- * Redistribution and use in source and binary forms, with or without
- * modification, are permitted provided that the following conditions are
- * met: redistributions of source code must retain the above copyright
- * notice, this list of conditions and the following disclaimer;
- * redistributions in binary form must reproduce the above copyright
- * notice, this list of conditions and the following disclaimer in the
- * documentation and/or other materials provided with the distribution;
- * neither the name of the copyright holders nor the names of its
- * contributors may be used to endorse or promote products derived from
- * this software without specific prior written permission.
- *
- * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
- * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
- * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
- * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
- * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
- * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
- * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
- * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
- * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
- * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
- * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
- *
- * Authors: Gabor Dozsa
- */
-
-/* @file
- * Device module for a full duplex ethernet link for multi gem5 simulations.
- */
-
-#include "dev/multi_etherlink.hh"
-
-#include <arpa/inet.h>
-#include <sys/socket.h>
-#include <unistd.h>
-
-#include <cmath>
-#include <deque>
-#include <string>
-#include <vector>
-
-#include "base/random.hh"
-#include "base/trace.hh"
-#include "debug/EthernetData.hh"
-#include "debug/MultiEthernet.hh"
-#include "debug/MultiEthernetPkt.hh"
-#include "dev/etherdump.hh"
-#include "dev/etherint.hh"
-#include "dev/etherlink.hh"
-#include "dev/etherobject.hh"
-#include "dev/etherpkt.hh"
-#include "dev/multi_iface.hh"
-#include "dev/tcp_iface.hh"
-#include "params/EtherLink.hh"
-#include "sim/core.hh"
-#include "sim/serialize.hh"
-#include "sim/system.hh"
-
-using namespace std;
-
-MultiEtherLink::MultiEtherLink(const Params *p)
-    : EtherObject(p)
-{
-    DPRINTF(MultiEthernet,"MultiEtherLink::MultiEtherLink() "
-            "link delay:%llu ticksPerByte:%f\n", p->delay, p->speed);
-
-    txLink = new TxLink(name() + ".link0", this, p->speed, p->delay_var,
-                        p->dump);
-    rxLink = new RxLink(name() + ".link1", this, p->delay, p->dump);
-
-    Tick sync_repeat;
-    if (p->sync_repeat != 0) {
-        if (p->sync_repeat != p->delay)
-            warn("MultiEtherLink(): sync_repeat is %lu and linkdelay is %lu",
-                 p->sync_repeat, p->delay);
-        sync_repeat = p->sync_repeat;
-    } else {
-        sync_repeat = p->delay;
-    }
-
-    // create the multi (TCP) interface to talk to the peer gem5 processes.
-    multiIface = new TCPIface(p->server_name, p->server_port,
-                              p->multi_rank, p->multi_size,
-                              p->sync_start, sync_repeat, this, p->is_switch,
-                              p->num_nodes);
-
-    localIface = new LocalIface(name() + ".int0", txLink, rxLink, multiIface);
-}
-
-MultiEtherLink::~MultiEtherLink()
-{
-    delete txLink;
-    delete rxLink;
-    delete localIface;
-    delete multiIface;
-}
-
-EtherInt*
-MultiEtherLink::getEthPort(const std::string &if_name, int idx)
-{
-    if (if_name != "int0") {
-        return nullptr;
-    } else {
-        panic_if(localIface->getPeer(), "interface already connected to");
-    }
-    return localIface;
-}
-
-void
-MultiEtherLink::serialize(CheckpointOut &cp) const
-{
-    multiIface->serializeSection(cp, "multiIface");
-    txLink->serializeSection(cp, "txLink");
-    rxLink->serializeSection(cp, "rxLink");
-}
-
-void
-MultiEtherLink::unserialize(CheckpointIn &cp)
-{
-    multiIface->unserializeSection(cp, "multiIface");
-    txLink->unserializeSection(cp, "txLink");
-    rxLink->unserializeSection(cp, "rxLink");
-}
-
-void
-MultiEtherLink::init()
-{
-    DPRINTF(MultiEthernet,"MultiEtherLink::init() called\n");
-    multiIface->init();
-}
-
-void
-MultiEtherLink::startup()
-{
-    DPRINTF(MultiEthernet,"MultiEtherLink::startup() called\n");
-    multiIface->startup();
-}
-
-void
-MultiEtherLink::RxLink::setMultiInt(MultiIface *m)
-{
-    assert(!multiIface);
-    multiIface = m;
-    // Spawn a new receiver thread that will process messages
-    // coming in from peer gem5 processes.
-    // The receive thread will also schedule a (receive) doneEvent
-    // for each incoming data packet.
-    multiIface->spawnRecvThread(&doneEvent, linkDelay);
-}
-
-void
-MultiEtherLink::RxLink::rxDone()
-{
-    assert(!busy());
-
-    // retrieve the packet that triggered the receive done event
-    packet = multiIface->packetIn();
-
-    if (dump)
-        dump->dump(packet);
-
-    DPRINTF(MultiEthernetPkt, "MultiEtherLink::MultiLink::rxDone() "
-            "packet received: len=%d\n", packet->length);
-    DDUMP(EthernetData, packet->data, packet->length);
-
-    localIface->sendPacket(packet);
-
-    packet = nullptr;
-}
-
-void
-MultiEtherLink::TxLink::txDone()
-{
-    if (dump)
-        dump->dump(packet);
-
-    packet = nullptr;
-    assert(!busy());
-
-    localIface->sendDone();
-}
-
-bool
-MultiEtherLink::TxLink::transmit(EthPacketPtr pkt)
-{
-    if (busy()) {
-        DPRINTF(MultiEthernet, "packet not sent, link busy\n");
-        return false;
-    }
-
-    packet = pkt;
-    Tick delay = (Tick)ceil(((double)pkt->length * ticksPerByte) + 1.0);
-    if (delayVar != 0)
-        delay += random_mt.random<Tick>(0, delayVar);
-
-    // send the packet to the peers
-    assert(multiIface);
-    multiIface->packetOut(pkt, delay);
-
-    // schedule the send done event
-    parent->schedule(doneEvent, curTick() + delay);
-
-    return true;
-}
-
-void
-MultiEtherLink::Link::serialize(CheckpointOut &cp) const
-{
-    bool packet_exists = (packet != nullptr);
-    SERIALIZE_SCALAR(packet_exists);
-    if (packet_exists)
-        packet->serialize("packet", cp);
-
-    bool event_scheduled = event->scheduled();
-    SERIALIZE_SCALAR(event_scheduled);
-    if (event_scheduled) {
-        Tick event_time = event->when();
-        SERIALIZE_SCALAR(event_time);
-    }
-}
-
-void
-MultiEtherLink::Link::unserialize(CheckpointIn &cp)
-{
-    bool packet_exists;
-    UNSERIALIZE_SCALAR(packet_exists);
-    if (packet_exists) {
-        packet = make_shared<EthPacketData>(16384);
-        packet->unserialize("packet", cp);
-    }
-
-    bool event_scheduled;
-    UNSERIALIZE_SCALAR(event_scheduled);
-    if (event_scheduled) {
-        Tick event_time;
-        UNSERIALIZE_SCALAR(event_time);
-        parent->schedule(*event, event_time);
-    }
-}
-
-MultiEtherLink::LocalIface::LocalIface(const std::string &name,
-                                       TxLink *tx,
-                                       RxLink *rx,
-                                       MultiIface *m) :
-    EtherInt(name), txLink(tx)
-{
-    tx->setLocalInt(this);
-    rx->setLocalInt(this);
-    tx->setMultiInt(m);
-    rx->setMultiInt(m);
-}
-
-MultiEtherLink *
-MultiEtherLinkParams::create()
-{
-    return new MultiEtherLink(this);
-}
-
-
diff --git a/src/dev/multi_etherlink.hh b/src/dev/multi_etherlink.hh
deleted file mode 100644
--- a/src/dev/multi_etherlink.hh
+++ /dev/null
@@ -1,234 +0,0 @@
-/*
- * Copyright (c) 2015 ARM Limited
- * All rights reserved
- *
- * The license below extends only to copyright in the software and shall
- * not be construed as granting a license to any other intellectual
- * property including but not limited to intellectual property relating
- * to a hardware implementation of the functionality of the software
- * licensed hereunder.  You may use the software subject to the license
- * terms below provided that you ensure that this notice is replicated
- * unmodified and in its entirety in all distributions of the software,
- * modified or unmodified, in source code or in binary form.
- *
- * Redistribution and use in source and binary forms, with or without
- * modification, are permitted provided that the following conditions are
- * met: redistributions of source code must retain the above copyright
- * notice, this list of conditions and the following disclaimer;
- * redistributions in binary form must reproduce the above copyright
- * notice, this list of conditions and the following disclaimer in the
- * documentation and/or other materials provided with the distribution;
- * neither the name of the copyright holders nor the names of its
- * contributors may be used to endorse or promote products derived from
- * this software without specific prior written permission.
- *
- * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
- * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
- * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
- * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
- * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
- * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
- * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
- * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
- * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
- * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
- * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
- *
- * Authors: Gabor Dozsa
- */
-
-/* @file
- * Device module for a full duplex ethernet link for multi gem5 simulations.
- *
- * See comments in dev/multi_iface.hh for a generic description of multi
- * gem5 simulations.
- *
- * This class is meant to be a drop in replacement for the EtherLink class for
- * multi gem5 runs.
- *
- */
-#ifndef __DEV_MULTIETHERLINK_HH__
-#define __DEV_MULTIETHERLINK_HH__
-
-#include <iostream>
-
-#include "dev/etherlink.hh"
-#include "params/MultiEtherLink.hh"
-
-class MultiIface;
-class EthPacketData;
-
-/**
- * Model for a fixed bandwidth full duplex ethernet link.
- */
-class MultiEtherLink : public EtherObject
-{
-  protected:
-    class LocalIface;
-
-    /**
-     * Model base class for a single uni-directional link.
-     *
-     * The link will encapsulate and transfer Ethernet packets to/from
-     * the message server.
-     */
-    class Link : public Serializable
-    {
-      protected:
-        std::string objName;
-        MultiEtherLink *parent;
-        LocalIface *localIface;
-        EtherDump *dump;
-        MultiIface *multiIface;
-        Event *event;
-        EthPacketPtr packet;
-
-      public:
-        Link(const std::string &name, MultiEtherLink *p,
-             EtherDump *d, Event *e) :
-            objName(name), parent(p), localIface(nullptr), dump(d),
-            multiIface(nullptr), event(e) {}
-
-        ~Link() {}
-
-        const std::string name() const { return objName; }
-        bool busy() const { return (bool)packet; }
-        void setLocalInt(LocalIface *i) { assert(!localIface); localIface=i; }
-
-        void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
-        void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
-    };
-
-    /**
-     * Model for a send link.
-     */
-    class TxLink : public Link
-    {
-      protected:
-        /**
-         * Per byte send delay
-         */
-        double ticksPerByte;
-        /**
-         * Random component of the send delay
-         */
-        Tick delayVar;
-
-        /**
-         * Send done callback. Called from doneEvent.
-         */
-        void txDone();
-        typedef EventWrapper<TxLink, &TxLink::txDone> DoneEvent;
-        friend void DoneEvent::process();
-        DoneEvent doneEvent;
-
-      public:
-        TxLink(const std::string &name, MultiEtherLink *p,
-               double invBW, Tick delay_var, EtherDump *d) :
-            Link(name, p, d, &doneEvent), ticksPerByte(invBW),
-            delayVar(delay_var), doneEvent(this) {}
-        ~TxLink() {}
-
-        /**
-         * Register the multi interface to be used to talk to the
-         * peer gem5 processes.
-         */
-        void setMultiInt(MultiIface *m) { assert(!multiIface); multiIface=m; }
-
-        /**
-         * Initiate sending of a packet via this link.
-         *
-         * @param packet Ethernet packet to send
-         */
-        bool transmit(EthPacketPtr packet);
-    };
-
-    /**
-     * Model for a receive link.
-     */
-    class RxLink : public Link
-    {
-      protected:
-
-        /**
-         * Transmission delay for the simulated Ethernet link.
-         */
-        Tick linkDelay;
-
-        /**
-         * Receive done callback method. Called from doneEvent.
-         */
-        void rxDone() ;
-        typedef EventWrapper<RxLink, &RxLink::rxDone> DoneEvent;
-        friend void DoneEvent::process();
-        DoneEvent doneEvent;
-
-      public:
-
-        RxLink(const std::string &name, MultiEtherLink *p,
-               Tick delay, EtherDump *d) :
-            Link(name, p, d, &doneEvent),
-            linkDelay(delay), doneEvent(this) {}
-        ~RxLink() {}
-
-        /**
-         * Register our multi interface to talk to the peer gem5 processes.
-         */
-        void setMultiInt(MultiIface *m);
-    };
-
-    /**
-     * Interface to the local simulated system
-     */
-    class LocalIface : public EtherInt
-    {
-      private:
-        TxLink *txLink;
-
-      public:
-        LocalIface(const std::string &name, TxLink *tx, RxLink *rx,
-                   MultiIface *m);
-
-        bool recvPacket(EthPacketPtr pkt) { return txLink->transmit(pkt); }
-        void sendDone() { peer->sendDone(); }
-        bool isBusy() { return txLink->busy(); }
-    };
-
-
-  protected:
-    /**
-     * Interface to talk to the peer gem5 processes.
-     */
-    MultiIface *multiIface;
-    /**
-     * Send link
-     */
-    TxLink *txLink;
-    /**
-     * Receive link
-     */
-    RxLink *rxLink;
-    LocalIface *localIface;
-
-  public:
-    typedef MultiEtherLinkParams Params;
-    MultiEtherLink(const Params *p);
-    ~MultiEtherLink();
-
-    const Params *
-    params() const
-    {
-        return dynamic_cast<const Params *>(_params);
-    }
-
-    virtual EtherInt *getEthPort(const std::string &if_name,
-                                 int idx) M5_ATTR_OVERRIDE;
-
-    virtual void init() M5_ATTR_OVERRIDE;
-    virtual void startup() M5_ATTR_OVERRIDE;
-
-    void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
-    void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
-};
-
-#endif // __DEV_MULTIETHERLINK_HH__
diff --git a/src/dev/multi_iface.cc b/src/dev/multi_iface.cc
deleted file mode 100644
--- a/src/dev/multi_iface.cc
+++ /dev/null
@@ -1,760 +0,0 @@
-/*
- * Copyright (c) 2015 ARM Limited
- * All rights reserved
- *
- * The license below extends only to copyright in the software and shall
- * not be construed as granting a license to any other intellectual
- * property including but not limited to intellectual property relating
- * to a hardware implementation of the functionality of the software
- * licensed hereunder.  You may use the software subject to the license
- * terms below provided that you ensure that this notice is replicated
- * unmodified and in its entirety in all distributions of the software,
- * modified or unmodified, in source code or in binary form.
- *
- * Redistribution and use in source and binary forms, with or without
- * modification, are permitted provided that the following conditions are
- * met: redistributions of source code must retain the above copyright
- * notice, this list of conditions and the following disclaimer;
- * redistributions in binary form must reproduce the above copyright
- * notice, this list of conditions and the following disclaimer in the
- * documentation and/or other materials provided with the distribution;
- * neither the name of the copyright holders nor the names of its
- * contributors may be used to endorse or promote products derived from
- * this software without specific prior written permission.
- *
- * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
- * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
- * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
- * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
- * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
- * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
- * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
- * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
- * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
- * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
- * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
- *
- * Authors: Gabor Dozsa
- */
-
-/* @file
- * The interface class for multi gem5 simulations.
- */
-
-#include "dev/multi_iface.hh"
-
-#include <queue>
-#include <thread>
-
-#include "base/random.hh"
-#include "base/trace.hh"
-#include "debug/MultiEthernet.hh"
-#include "debug/MultiEthernetPkt.hh"
-#include "dev/etherpkt.hh"
-#include "sim/sim_exit.hh"
-#include "sim/sim_object.hh"
-
-using namespace std;
-MultiIface::Sync *MultiIface::sync = nullptr;
-MultiIface::SyncEvent *MultiIface::syncEvent = nullptr;
-unsigned MultiIface::recvThreadsNum = 0;
-MultiIface *MultiIface::master = nullptr;
-
-void
-MultiIface::Sync::init(Tick start_tick, Tick repeat_tick)
-{
-    if (start_tick < firstAt) {
-        firstAt = start_tick;
-        inform("Next multi synchronisation tick is changed to %lu.\n", nextAt);
-    }
-
-    if (repeat_tick == 0)
-        panic("Multi synchronisation interval must be greater than zero");
-
-    if (repeat_tick < nextRepeat) {
-        nextRepeat = repeat_tick;
-        inform("Multi synchronisation interval is changed to %lu.\n",
-               nextRepeat);
-    }
-}
-
-MultiIface::SyncSwitch::SyncSwitch(int num_nodes)
-{
-    numNodes = num_nodes;
-    waitNum = num_nodes;
-    numExitReq = 0;
-    numCkptReq = 0;
-    doExit = false;
-    doCkpt = false;
-    firstAt = std::numeric_limits<Tick>::max();
-    nextAt = 0;
-    nextRepeat = std::numeric_limits<Tick>::max();
-}
-
-MultiIface::SyncNode::SyncNode()
-{
-    waitNum = 0;
-    needExit = ReqType::none;
-    needCkpt = ReqType::none;
-    doExit = false;
-    doCkpt = false;
-    firstAt = std::numeric_limits<Tick>::max();
-    nextAt = 0;
-    nextRepeat = std::numeric_limits<Tick>::max();
-}
-
-void
-MultiIface::SyncNode::run(bool same_tick)
-{
-    std::unique_lock<std::mutex> sync_lock(lock);
-    Header header;
-
-    assert(waitNum == 0);
-    waitNum = MultiIface::recvThreadsNum;
-    // initiate the global synchronisation
-    header.msgType = MsgType::cmdSyncReq;
-    header.sendTick = curTick();
-    header.syncRepeat = nextRepeat;
-    header.needCkpt = needCkpt;
-    if (needCkpt != ReqType::none)
-        needCkpt = ReqType::pending;
-    header.needExit = needExit;
-    if (needCkpt != ReqType::none)
-        needCkpt = ReqType::pending;
-    MultiIface::master->sendCmd(header);
-    // now wait until all receiver threads complete the synchronisation
-    auto lf = [this]{ return waitNum == 0; };
-    cv.wait(sync_lock, lf);
-    // global barrier is done
-    assert(!same_tick || (nextAt == curTick()));
-}
-
-
-void
-MultiIface::SyncSwitch::run(bool same_tick)
-{
-    std::unique_lock<std::mutex> sync_lock(lock);
-    Header header;
-    if (waitNum > 0) {
-        auto lf = [this]{ return waitNum == 0; };
-        cv.wait(sync_lock, lf);
-    }
-    assert(waitNum == 0);
-    assert(!same_tick || (nextAt == curTick()));
-    waitNum = numNodes;
-    // initiate the global synchronisation
-    header.msgType = MsgType::cmdSyncAck;
-    //header.sendTick = curTick();
-    header.sendTick = nextAt;
-    header.syncRepeat = nextRepeat;
-    if (doCkpt || numCkptReq == numNodes) {
-        doCkpt = true;
-        header.needCkpt = ReqType::immediate;
-        numCkptReq = 0;
-    } else {
-        header.needCkpt = ReqType::none;
-    }
-    if (doExit || numExitReq == numNodes) {
-        doExit = true;
-        header.needExit = ReqType::immediate;
-    } else {
-        header.needExit = ReqType::none;
-    }
-    MultiIface::master->sendCmd(header);
-}
-
-void
-MultiIface::SyncSwitch::progress(Tick send_tick,
-                                 Tick sync_repeat,
-                                 ReqType need_ckpt,
-                                 ReqType need_exit)
-{
-    std::unique_lock<std::mutex> sync_lock(lock);
-    assert(waitNum > 0);
-
-    if (send_tick > nextAt)
-        nextAt = send_tick;
-    if (nextRepeat > sync_repeat)
-        nextRepeat = sync_repeat;
-
-    if (need_ckpt == ReqType::collective)
-        numCkptReq++;
-    if (need_ckpt == ReqType::immediate)
-        doCkpt = true;
-    if (need_exit == ReqType::collective)
-        numExitReq++;
-    if (need_exit == ReqType::immediate)
-        doExit = true;
-
-    waitNum--;
-    // Notify the simulation thread if the on-going sync is complete
-    if (waitNum == 0) {
-        sync_lock.unlock();
-        cv.notify_one();
-    }
-}
-
-void
-MultiIface::SyncNode::progress(Tick max_send_tick,
-                               Tick next_repeat,
-                               ReqType do_ckpt,
-                               ReqType do_exit)
-{
-    std::unique_lock<std::mutex> sync_lock(lock);
-    assert(waitNum > 0);
-
-    nextAt = max_send_tick;
-    nextRepeat = next_repeat;
-    doCkpt = (do_ckpt != ReqType::none);
-    doExit = (do_exit != ReqType::none);
-
-    waitNum--;
-    // Notify the simulation thread if the on-going sync is complete
-    if (waitNum == 0) {
-        sync_lock.unlock();
-        cv.notify_one();
-    }
-}
-
-void
-MultiIface::SyncNode::requestCkpt(ReqType req)
-{
-   std::lock_guard<std::mutex> sync_lock(lock);
-   assert(req != ReqType::none);
-   if (needCkpt != ReqType::none)
-       warn("Ckpt requested multiple times (req:%d)\n", static_cast<int>(req));
-   if (needCkpt == ReqType::none || req == ReqType::immediate)
-       needCkpt = req;
-}
-
-void
-MultiIface::SyncNode::requestExit(ReqType req)
-{
-   std::lock_guard<std::mutex> sync_lock(lock);
-   assert(req != ReqType::none);
-   if (needExit != ReqType::none)
-       warn("Exit requested multiple times (req:%d)\n", static_cast<int>(req));
-   if (needExit == ReqType::none || req == ReqType::immediate)
-       needExit = req;
-}
-
-void
-MultiIface::Sync::drainComplete()
-{
-    if (doCkpt) {
-        // The first MultiIface object called this right before writing the
-        // checkpoint. We need to drain the underlying physical network here.
-        // Note that other gem5 peers may enter this barrier at different
-        // ticks due to draining.
-        run(false);
-        // Only the "first" MultiIface object has to perform the sync
-        doCkpt = false;
-    }
-}
-
-void
-MultiIface::SyncNode::serialize(CheckpointOut &cp) const
-{
-    int need_exit = static_cast<int>(needExit);
-    SERIALIZE_SCALAR(need_exit);
-}
-
-void
-MultiIface::SyncNode::unserialize(CheckpointIn &cp)
-{
-    int need_exit;
-    UNSERIALIZE_SCALAR(need_exit);
-    needExit = static_cast<ReqType>(need_exit);
-}
-
-void
-MultiIface::SyncSwitch::serialize(CheckpointOut &cp) const
-{
-    SERIALIZE_SCALAR(numExitReq);
-}
-
-void
-MultiIface::SyncSwitch::unserialize(CheckpointIn &cp)
-{
-    UNSERIALIZE_SCALAR(numExitReq);
-}
-
-void
-MultiIface::SyncEvent::start()
-{
-    // Note that this may be called either from startup() or drainResume()
-
-    // At this point, all MultiIface objects ha already called Sync::init() so
-    // we have a local minimum of the start tick and repeat for the periodic
-    // sync.
-    Tick firstAt  = MultiIface::sync->firstAt;
-    repeat = MultiIface::sync->nextRepeat;
-    // Do a global barrier to agree on a common repeat value (the smallest
-    // one from all participating nodes
-    MultiIface::sync->run(curTick() == 0);
-
-    assert(!MultiIface::sync->doCkpt);
-    assert(!MultiIface::sync->doExit);
-    assert(MultiIface::sync->nextAt >= curTick());
-    assert(MultiIface::sync->nextRepeat <= repeat);
-
-    // if this is called at tick 0 then we use the config start param otherwise
-    // the maximum of the current tick of all participating nodes
-    if (curTick() == 0) {
-        assert(!scheduled());
-        assert(MultiIface::sync->nextAt == 0);
-        schedule(firstAt);
-    } else {
-        if (scheduled())
-            reschedule(MultiIface::sync->nextAt);
-        else
-            schedule(MultiIface::sync->nextAt);
-    }
-    inform("Multi sync scheduled at %lu and repeats %lu\n",  when(),
-           MultiIface::sync->nextRepeat);
-}
-
-void
-MultiIface::SyncEvent::process()
-{
-    /*
-     * Note that this is a global event so this process method will be called
-     * by only exactly one thread.
-     */
-    /*
-     * We hold the eventq lock at this point but the receiver thread may
-     * need the lock to schedule new recv events while waiting for the
-     * multi sync to complete.
-     * Note that the other simulation threads also release their eventq
-     * locks while waiting for us due to the global event semantics.
-     */
-    {
-        EventQueue::ScopedRelease sr(curEventQueue());
-        // we do a global sync here that is supposed to happen at the same
-        // tick in all gem5 peers
-        MultiIface::sync->run(true);
-        // global sync completed
-    }
-    if (MultiIface::sync->doCkpt)
-        exitSimLoop("checkpoint");
-    if (MultiIface::sync->doExit)
-        exitSimLoop("exit request from gem5 peers");
-
-    // schedule the next periodic sync
-    repeat = MultiIface::sync->nextRepeat;
-    schedule(curTick() + repeat);
-}
-
-void
-MultiIface::RecvScheduler::init(Event *recv_done, Tick link_delay)
-{
-    // This is called from the receiver thread when it starts running. The new
-    // receiver thread shares the event queue with the simulation thread
-    // (associated with the simulated Ethernet link).
-    curEventQueue(eventManager->eventQueue());
-
-    recvDone = recv_done;
-    linkDelay = link_delay;
-}
-
-Tick
-MultiIface::RecvScheduler::calcReceiveTick(Tick send_tick,
-                                           Tick send_delay,
-                                           Tick prev_recv_tick)
-{
-    Tick recv_tick = send_tick + send_delay + linkDelay;
-    // sanity check (we need atleast a send delay long window)
-    assert(recv_tick >= prev_recv_tick + send_delay);
-    panic_if(prev_recv_tick + send_delay > recv_tick,
-             "Receive window is smaller than send delay");
-    panic_if(recv_tick <= curTick(),
-             "Simulators out of sync - missed packet receive by %llu ticks"
-             "(rev_recv_tick: %lu send_tick: %lu send_delay: %lu "
-             "linkDelay: %lu )",
-             curTick() - recv_tick, prev_recv_tick, send_tick, send_delay,
-             linkDelay);
-
-    return recv_tick;
-}
-
-void
-MultiIface::RecvScheduler::resumeRecvTicks()
-{
-    // Schedule pending packets asap in case link speed/delay changed when
-    // resuming from the checkpoint.
-    // This may be done during unserialize except that curTick() is unknown.
-    std::vector<Desc> v;
-    while (!descQueue.empty()) {
-        Desc d = descQueue.front();
-        descQueue.pop();
-        d.sendTick = curTick();
-        d.sendDelay = d.packet->size(); // assume 1 tick/byte max link speed
-        v.push_back(d);
-    }
-
-    for (auto &d : v)
-        descQueue.push(d);
-
-    if (recvDone->scheduled()) {
-        assert(!descQueue.empty());
-        eventManager->reschedule(recvDone, curTick());
-    } else {
-        assert(descQueue.empty() && v.empty());
-    }
-}
-
-void
-MultiIface::RecvScheduler::pushPacket(EthPacketPtr new_packet,
-                                      Tick send_tick,
-                                      Tick send_delay)
-{
-    // Note : this is called from the receiver thread
-    curEventQueue()->lock();
-    Tick recv_tick = calcReceiveTick(send_tick, send_delay, prevRecvTick);
-
-    DPRINTF(MultiEthernetPkt, "MultiIface::recvScheduler::pushPacket "
-            "send_tick:%llu send_delay:%llu link_delay:%llu recv_tick:%llu\n",
-            send_tick, send_delay, linkDelay, recv_tick);
-    // Every packet must be sent and arrive in the same quantum
-    assert(send_tick > master->syncEvent->when() -
-           master->syncEvent->repeat);
-    // No packet may be scheduled for receive in the arrivel quantum
-    assert(send_tick + send_delay + linkDelay > master->syncEvent->when());
-
-    // Now we are about to schedule a recvDone event for the new data packet.
-    // We use the same recvDone object for all incoming data packets. Packet
-    // descriptors are saved in the ordered queue. The currently scheduled
-    // packet is always on the top of the queue.
-    // NOTE:  we use the event queue lock to protect the receive desc queue,
-    // too, which is accessed both by the receiver thread and the simulation
-    // thread.
-    descQueue.emplace(new_packet, send_tick, send_delay);
-    if (descQueue.size() == 1) {
-        assert(!recvDone->scheduled());
-        eventManager->schedule(recvDone, recv_tick);
-    } else {
-        assert(recvDone->scheduled());
-        panic_if(descQueue.front().sendTick + descQueue.front().sendDelay > recv_tick,
-                 "Out of order packet received (recv_tick: %lu top(): %lu\n",
-                 recv_tick, descQueue.front().sendTick + descQueue.front().sendDelay);
-    }
-    curEventQueue()->unlock();
-}
-
-EthPacketPtr
-MultiIface::RecvScheduler::popPacket()
-{
-    // Note : this is called from the simulation thread when a receive done
-    // event is being processed for the link. We assume that the thread holds
-    // the event queue queue lock when this is called!
-    EthPacketPtr next_packet = descQueue.front().packet;
-    descQueue.pop();
-
-    if (descQueue.size() > 0) {
-        Tick recv_tick = calcReceiveTick(descQueue.front().sendTick,
-                                         descQueue.front().sendDelay,
-                                         curTick());
-        eventManager->schedule(recvDone, recv_tick);
-    }
-    prevRecvTick = curTick();
-    return next_packet;
-}
-
-void
-MultiIface::RecvScheduler::Desc::serialize(CheckpointOut &cp) const
-{
-        SERIALIZE_SCALAR(sendTick);
-        SERIALIZE_SCALAR(sendDelay);
-        packet->serialize("rxPacket", cp);
-}
-
-void
-MultiIface::RecvScheduler::Desc::unserialize(CheckpointIn &cp)
-{
-        UNSERIALIZE_SCALAR(sendTick);
-        UNSERIALIZE_SCALAR(sendDelay);
-        packet = std::make_shared<EthPacketData>(16384);
-        packet->unserialize("rxPacket", cp);
-}
-
-void
-MultiIface::RecvScheduler::serialize(CheckpointOut &cp) const
-{
-    SERIALIZE_SCALAR(prevRecvTick);
-    // serialize the receive desc queue
-    std::queue<Desc> tmp_queue(descQueue);
-    unsigned n_desc_queue = descQueue.size();
-    assert(tmp_queue.size() == descQueue.size());
-    SERIALIZE_SCALAR(n_desc_queue);
-    for (int i = 0; i < n_desc_queue; i++) {
-        tmp_queue.front().serializeSection(cp, csprintf("rxDesc_%d", i));
-        tmp_queue.pop();
-    }
-    assert(tmp_queue.empty());
-}
-
-void
-MultiIface::RecvScheduler::unserialize(CheckpointIn &cp)
-{
-    assert(descQueue.size() == 0);
-    assert(recvDone->scheduled() == false);
-
-    UNSERIALIZE_SCALAR(prevRecvTick);
-    // unserialize the receive desc queue
-    unsigned n_desc_queue;
-    UNSERIALIZE_SCALAR(n_desc_queue);
-    for (int i = 0; i < n_desc_queue; i++) {
-        Desc recv_desc;
-        recv_desc.unserializeSection(cp, csprintf("rxDesc_%d", i));
-        descQueue.push(recv_desc);
-    }
-}
-
-MultiIface::MultiIface(unsigned multi_rank,
-                       unsigned multi_size,
-                       Tick sync_start,
-                       Tick sync_repeat,
-                       EventManager *em,
-                       bool is_switch, int num_nodes) :
-    syncStart(sync_start), syncRepeat(sync_repeat),
-    recvThread(nullptr), recvScheduler(em),
-    rank(multi_rank), size(multi_size)
-{
-    DPRINTF(MultiEthernet, "MultiIface() ctor rank:%d\n",multi_rank);
-    isMaster = false;
-    if (master == nullptr) {
-        assert(sync == nullptr);
-        assert(syncEvent == nullptr);
-        if (is_switch)
-            sync = new SyncSwitch(num_nodes);
-        else
-            sync = new SyncNode();
-        syncEvent = new SyncEvent();
-        master = this;
-        isMaster = true;
-    }
-}
-
-MultiIface::~MultiIface()
-{
-    assert(recvThread);
-    delete recvThread;
-    if (this == master) {
-        assert(syncEvent);
-        delete syncEvent;
-        assert(sync);
-        delete sync;
-        master = nullptr;
-    }
-}
-
-void
-MultiIface::packetOut(EthPacketPtr pkt, Tick send_delay)
-{
-    Header header;
-
-    // Prepare a multi header packet for the Ethernet packet we want to
-    // send out.
-    header.msgType = MsgType::dataDescriptor;
-    header.sendTick  = curTick();
-    header.sendDelay = send_delay;
-
-    header.dataPacketLength = pkt->size();
-
-    // Send out the packet and the meta info.
-    sendPacket(header, pkt);
-
-    DPRINTF(MultiEthernetPkt,
-            "MultiIface::sendDataPacket() done size:%d send_delay:%llu\n",
-            pkt->size(), send_delay);
-}
-
-void
-MultiIface::recvThreadFunc(Event *recv_done, Tick link_delay)
-{
-    EthPacketPtr new_packet;
-    MultiHeaderPkt::Header header;
-
-    // Initialize receive scheduler parameters
-    recvScheduler.init(recv_done, link_delay);
-
-    // Main loop to wait for and process any incoming message.
-    for (;;) {
-        // recvHeader() blocks until the next multi header packet comes in.
-        if (!recvHeader(header)) {
-            // We lost connection to the peer gem5 processes most likely
-            // because one of them called m5 exit. So we stop here.
-            // Grab the eventq lock to stop the simulation thread
-            curEventQueue()->lock();
-            exit_message("info",
-                         0,
-                         "Message server closed connection, "
-                         "simulation is exiting");
-        }
-
-        // We got a valid multi header packet, let's process it
-        if (header.msgType == MsgType::dataDescriptor) {
-            recvPacket(header, new_packet);
-            recvScheduler.pushPacket(new_packet,
-                                     header.sendTick,
-                                     header.sendDelay);
-        } else {
-            // everything else must be synchronisation related command
-            sync->progress(header.sendTick,
-                           header.syncRepeat,
-                           header.needCkpt,
-                           header.needExit);
-        }
-    }
-}
-
-void
-MultiIface::spawnRecvThread(Event *recv_done, Tick link_delay)
-{
-    assert(recvThread == nullptr);
-
-    recvThread = new std::thread(&MultiIface::recvThreadFunc,
-                                 this,
-                                 recv_done,
-                                 link_delay);
-    recvThreadsNum++;
-}
-
-DrainState
-MultiIface::drain()
-{
-    DPRINTF(MultiEthernet,"MultiIFace::drain() called\n");
-
-    // This can be called multiple times in the same drain cycle.
-    return DrainState::Drained;
-}
-
-void
-MultiIface::drainResume() {
-    if (master == this) {
-        syncEvent->start();
-    }
-    recvScheduler.resumeRecvTicks();
-}
-
-void
-MultiIface::serialize(CheckpointOut &cp) const
-{
-    // Drain the multi interface before the checkpoint is taken. We cannot call
-    // this as part of the normal drain cycle because this multi sync has to be
-    // called exactly once after the system is fully drained.
-    sync->drainComplete();
-
-    recvScheduler.serializeSection(cp, "recvScheduler");
-    if (this == master) {
-        sync->serializeSection(cp, "Sync");
-    }
-}
-
-void
-MultiIface::unserialize(CheckpointIn &cp)
-{
-    recvScheduler.unserializeSection(cp, "recvScheduler");
-    if (this == master) {
-        sync->unserializeSection(cp, "Sync");
-  }
-}
-
-void
-MultiIface::init()
-{
-    // Adjust the periodic sync start and interval. Different MultiIface
-    // might have different requirements. The singleton sync object
-    // will select the minimum values for both params.
-    assert(sync != nullptr);
-    sync->init(syncStart, syncRepeat);
-
-    // Initialize the seed for random generator to avoid the same sequence
-    // in all gem5 peer processes
-    assert(master != nullptr);
-    if (this == master)
-        random_mt.init(5489 * (rank+1) + 257);
-}
-
-void
-MultiIface::startup()
-{
-    DPRINTF(MultiEthernet, "MultiIface::startup() started\n");
-    // If this run is a resume from a checkpoint than we schedule the first
-    // periodic sync in drainResume()
-    if (curTick() == 0 && this == master)
-        syncEvent->start();
-
-    DPRINTF(MultiEthernet, "MultiIface::startup() done\n");
-}
-
-bool
-MultiIface::readyToCkpt(Tick delay, Tick period)
-{
-    bool ret = true;
-    DPRINTF(MultiEthernet, "MultiIface::readyToCkpt() called, delay:%lu "
-            "period:%lu\n", delay, period);
-    if (master) {
-        if (delay == 0) {
-            inform("m5 checkpoint called with zero delay => triggering collaborative "
-                   "checkpoint\n");
-            sync->requestCkpt(ReqType::collective);
-        } else {
-            inform("m5 checkpoint called with non-zero delay => triggering immediate "
-                   "checkpoint (at the next sync)\n");
-            sync->requestCkpt(ReqType::immediate);
-        }
-        if (period != 0)
-            inform("Non-zero period for m5_ckpt is ignored in "
-                   "distributed gem5 runs\n");
-        ret = false;
-    }
-    return ret;
-}
-
-bool
-MultiIface::readyToExit(Tick delay)
-{
-    bool ret = true;
-    DPRINTF(MultiEthernet, "MultiIface::readyToExit() called, delay:%lu\n",
-            delay);
-    if (master) {
-        if (delay == 0) {
-            inform("m5 exit called with zero delay => triggering collaborative "
-                   "exit\n");
-            sync->requestExit(ReqType::collective);
-        } else {
-            inform("m5 exit called with non-zero delay => triggering immediate "
-                   "exit (at the next sync)\n");
-            sync->requestExit(ReqType::immediate);
-        }
-        ret = false;
-    }
-    return ret;
-}
-
-uint64_t
-MultiIface::rankParam()
-{
-    uint64_t val;
-    if (master) {
-        val = master->rank;
-    } else {
-        warn("Multi-rank parameter is queried in single gem5 simulation.");
-        val = 0;
-    }
-    return val;
-}
-
-uint64_t
-MultiIface::sizeParam()
-{
-    uint64_t val;
-    if (master) {
-        val = master->size;
-    } else {
-        warn("Multi-size parameter is queried in single gem5 simulation.");
-        val = 1;
-    }
-    return val;
-}
diff --git a/src/dev/multi_iface.hh b/src/dev/multi_iface.hh
deleted file mode 100644
--- a/src/dev/multi_iface.hh
+++ /dev/null
@@ -1,564 +0,0 @@
-/*
- * Copyright (c) 2015 ARM Limited
- * All rights reserved
- *
- * The license below extends only to copyright in the software and shall
- * not be construed as granting a license to any other intellectual
- * property including but not limited to intellectual property relating
- * to a hardware implementation of the functionality of the software
- * licensed hereunder.  You may use the software subject to the license
- * terms below provided that you ensure that this notice is replicated
- * unmodified and in its entirety in all distributions of the software,
- * modified or unmodified, in source code or in binary form.
- *
- * Redistribution and use in source and binary forms, with or without
- * modification, are permitted provided that the following conditions are
- * met: redistributions of source code must retain the above copyright
- * notice, this list of conditions and the following disclaimer;
- * redistributions in binary form must reproduce the above copyright
- * notice, this list of conditions and the following disclaimer in the
- * documentation and/or other materials provided with the distribution;
- * neither the name of the copyright holders nor the names of its
- * contributors may be used to endorse or promote products derived from
- * this software without specific prior written permission.
- *
- * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
- * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
- * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
- * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
- * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
- * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
- * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
- * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
- * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
- * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
- * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
- *
- * Authors: Gabor Dozsa
- */
-
-/* @file
- * The interface class for multi gem5 simulations.
- *
- * Multi gem5 is an extension to gem5 to enable parallel simulation of a
- * distributed system (e.g. simulation of a pool of machines
- * connected by Ethernet links). A multi gem5 run consists of seperate gem5
- * processes running in parallel. Each gem5 process executes
- * the simulation of a component of the simulated distributed system.
- * (An example component can be a multi-core board with an Ethernet NIC.)
- * The MultiIface class below provides services to transfer data and
- * control messages among the gem5 processes. The main such services are
- * as follows.
- *
- * 1. Send a data packet coming from a simulated Ethernet link. The packet
- * will be transferred to (all) the target(s) gem5 processes. The send
- * operation is always performed by the simulation thread, i.e. the gem5
- * thread that is processing the event queue associated with the simulated
- * Ethernet link.
- *
- * 2. Spawn a receiver thread to process messages coming in from the
- * from other gem5 processes. Each simulated Ethernet link has its own
- * associated receiver thread. The receiver thread saves the incoming packet
- * and schedule an appropriate receive event in the event queue.
- *
- * 3. Schedule a global barrier event periodically to keep the gem5
- * processes in sync.
- * Periodic barrier event to keep peer gem5 processes in sync. The basic idea
- * is that no gem5 process can go ahead further than the simulated link
- * transmission delay to ensure that a corresponding receive event can always
- * be scheduled for any message coming in from a peer gem5 process.
- *
- *
- *
- * This interface is an abstract class (sendRaw() and recvRaw()
- * methods are pure virtual). It can work with various low level
- * send/receive service implementations (e.g. TCP/IP, MPI,...). A TCP
- * stream socket version is implemented in dev/src/tcp_iface.[hh,cc].
- */
-#ifndef __DEV_MULTI_IFACE_HH__
-#define __DEV_MULTI_IFACE_HH__
-
-#include <array>
-#include <mutex>
-#include <queue>
-#include <thread>
-#include <utility>
-
-#include "dev/etherpkt.hh"
-#include "dev/multi_packet.hh"
-#include "sim/core.hh"
-#include "sim/drain.hh"
-#include "sim/global_event.hh"
-#include "sim/serialize.hh"
-
-class EventManager;
-
-/**
- * The interface class to talk to peer gem5 processes.
- */
-class MultiIface : public Drainable, public Serializable
-{
-  public:
-    typedef MultiHeaderPkt::Header Header;
-
-  protected:
-    typedef MultiHeaderPkt::MsgType MsgType;
-    typedef MultiHeaderPkt::ReqType ReqType;
-
-  private:
-    class SyncEvent;
-    /** @class Sync
-     * This class implements global sync operations among gem5 peer processes.
-     *
-     * @note This class is used as a singleton object (shared by all MultiIface
-     * objects).
-     */
-    class Sync : public Serializable
-    {
-      protected:
-        /**
-         * The lock to protect access to the Sync object.
-         */
-        std::mutex lock;
-        /**
-         * Condition variable for the simulation thread to wait on
-         * until all receiver threads completes the current global
-         * synchronisation.
-         */
-        std::condition_variable cv;
-        /**
-         * Number of receiver threads that not yet completed the current global
-         * synchronisation.
-         */
-        unsigned waitNum;
-        /**
-         * Flag is set if exit is permitted upon sync completion
-         */
-        bool doExit;
-        /**
-         * Flag is set if taking a ckpt is permitted upon sync completion
-         */
-        bool doCkpt;
-        /**
-         * The repeat value for the next periodic sync
-         */
-        Tick nextRepeat;
-        /**
-         * Tick for the very first periodic sync
-         */
-        Tick firstAt;
-        /**
-         * Tick for the next periodic sync (if the event is not scheduled yet)
-         */
-        Tick nextAt;
-
-        friend class SyncEvent;
-
-      public:
-        /**
-         * Initialize periodic sync params.
-         *
-         * @param start Start tick for multi synchronisation
-         * @param repeat Frequency of multi synchronisation
-         *
-         */
-        void init(Tick start, Tick repeat);
-        /**
-         *  Core method to perform a full multi sync.
-         */
-        virtual void run(bool same_tick) = 0;
-        /**
-         * Callback when the receiver thread gets a sync ack message.
-         */
-        virtual void progress(Tick send_tick,
-                              Tick next_repeat,
-                              ReqType do_ckpt,
-                              ReqType do_exit) = 0;
-
-        virtual void requestCkpt(ReqType req) = 0;
-        virtual void requestExit(ReqType req) = 0;
-
-        void drainComplete();
-
-        virtual void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE = 0;
-        virtual void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE = 0;
-    };
-
-    class SyncNode: public Sync
-    {
-      private:
-        /**
-         * Exit requested
-         */
-        ReqType needExit;
-        /**
-         * Ckpt requested
-         */
-        ReqType needCkpt;
-
-      public:
-
-        SyncNode();
-        ~SyncNode() {}
-        void run(bool same_tick) M5_ATTR_OVERRIDE;
-        void progress(Tick max_req_tick,
-                      Tick next_repeat,
-                      ReqType do_ckpt,
-                      ReqType do_exit) M5_ATTR_OVERRIDE;
-
-        void requestCkpt(ReqType req) M5_ATTR_OVERRIDE;
-        void requestExit(ReqType req) M5_ATTR_OVERRIDE;
-
-        void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
-        void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
-    };
-
-    class SyncSwitch: public Sync
-    {
-      private:
-        /**
-         * Counter for recording exit requests
-         */
-        unsigned numExitReq;
-        /**
-         * Counter for recording ckpt requests
-         */
-        unsigned numCkptReq;
-        /**
-         *  Number of connected simulated nodes
-         */
-        unsigned numNodes;
-
-      public:
-        SyncSwitch(int num_nodes);
-        ~SyncSwitch() {}
-
-        void run(bool same_tick) M5_ATTR_OVERRIDE;
-        void progress(Tick max_req_tick,
-                      Tick next_repeat,
-                      ReqType do_ckpt,
-                      ReqType do_exit) M5_ATTR_OVERRIDE;
-
-        void requestCkpt(ReqType) M5_ATTR_OVERRIDE {
-            panic("Switch requested checkpoint");
-        }
-        void requestExit(ReqType) M5_ATTR_OVERRIDE {
-            panic("Switch requested exit");
-        }
-
-        void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
-        void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
-    };
-
-    /**
-     * The global event to schedule peridic multi sync. It is used as a
-     * singleton object.
-     *
-     * The periodic synchronisation works as follows.
-     * 1. A MultisyncEvent is scheduled as a global event when startup() is
-     * called.
-     * 2. The progress() method of the MultisyncEvent initiates a new barrier
-     * for each simulated Ethernet links.
-     * 3. Simulation thread(s) then waits until all receiver threads
-     * completes the ongoing barrier. The global sync event is done.
-     */
-    class SyncEvent : public GlobalSyncEvent
-    {
-      public:
-        /**
-         * Only the firstly instantiated MultiIface object will
-         * call this constructor.
-         */
-        SyncEvent() : GlobalSyncEvent(Sim_Exit_Pri, 0) {}
-
-        ~SyncEvent() {}
-        /**
-         * Schedule the first periodic sync event.
-         */
-        void start();
-        /**
-         * This is a global event so process() will be called by each
-         * simulation threads. (See further comments in the .cc file.)
-         */
-        void process() M5_ATTR_OVERRIDE;
-    };
-    /**
-     * Class to encapsulate information about data packets received.
-
-     * @note The main purpose of the class to take care of scheduling receive
-     * done events for the simulated network link and store incoming packets
-     * until they can be received by the simulated network link.
-     */
-    class RecvScheduler : public Serializable
-    {
-      private:
-        /**
-         * Received packet descriptor. This information is used by the receive
-         * thread to schedule receive events and by the simulation thread to
-         * process those events.
-         */
-        struct Desc : public Serializable {
-            EthPacketPtr packet;
-            Tick sendTick;
-            Tick sendDelay;
-
-            Desc() : sendTick(0), sendDelay(0) {}
-            Desc(EthPacketPtr p, Tick s, Tick d) :
-                packet(p), sendTick(s), sendDelay(d) {}
-            Desc(const Desc &d) :
-                packet(d.packet), sendTick(d.sendTick), sendDelay(d.sendDelay) {}
-
-            void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
-            void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
-        };
-        /**
-         * The queue to store the receive descriptors.
-         */
-        std::queue<Desc> descQueue;
-        /**
-         * The tick when the most recent receive event was processed.
-         *
-         * @note This information is necessary to simulate possible receiver
-         * link contention when calculating the receive tick for the next
-         * incoming data packet (see the calcReceiveTick() method)
-         */
-        Tick prevRecvTick;
-        /**
-         * The receive done event for the simulated Ethernet link.
-         *
-         * @note This object is constructed by the simulated network link. We
-         * schedule this object for each incoming data packet.
-         */
-        Event *recvDone;
-        /**
-         * The link delay in ticks for the simulated Ethernet link.
-         *
-         * @note This value is used for calculating the receive ticks for an
-         * incoming data packets.
-         */
-        Tick linkDelay;
-        /**
-         * The event manager associated with the simulated Ethernet link.
-         *
-         * @note It is used to access the event queue for scheduling receive
-         * done events for the link.
-         */
-        EventManager *eventManager;
-        /**
-         * Calculate the tick to schedule the next receive done event.
-         *
-         * @param send_tick The tick the packet was sent.
-         * @param send_delay The simulated delay at the sender side.
-         * @param prev_recv_tick Tick when the last receive event was
-         * processed.
-         *
-         * @note This method tries to take into account possible receiver link
-         * contention and adjust receive tick for the incoming packets
-         * accordingly.
-         */
-        Tick calcReceiveTick(Tick send_tick,
-                             Tick send_delay,
-                             Tick prev_recv_tick);
-
-
-      public:
-        /**
-         * Scheduler for the incoming data packets.
-         *
-         * @param em The event manager associated with the simulated Ethernet
-         * link.
-         */
-        RecvScheduler(EventManager *em) :
-            prevRecvTick(0), recvDone(nullptr), linkDelay(0),
-            eventManager(em) {}
-
-        /**
-         *  Initialize network link parameters.
-         *
-         * @note This method is called from the receiver thread (see
-         * recvThreadFunc()).
-         */
-        void init(Event *recv_done, Tick link_delay);
-        /**
-         * Fetch the next packet that is to be received by the simulated network
-         * link.
-         *
-         * @note This method is called from the process() method of the receive
-         * done event associated with the network link.
-         */
-        EthPacketPtr popPacket();
-        /**
-         * Push a newly arrived packet into the desc queue.
-         */
-        void pushPacket(EthPacketPtr new_packet,
-                        Tick send_tick,
-                        Tick send_delay);
-
-        void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
-        void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
-        /**
-         * Adjust receive ticks for pending packets when resuming from a
-         * checkpoint
-         *
-         * @note Link speed and delay parameters may change at resume.
-         */
-        void resumeRecvTicks();
-  };
-    /**
-     * Tick to schedule the first multi sync event.
-     * This is just as optimization : we do not need any multi sync
-     * event until the simulated NIC is brought up by the OS.
-     */
-    Tick syncStart;
-    /**
-     * Frequency of multi sync events in ticks.
-     */
-    Tick syncRepeat;
-    /**
-     * Receiver thread pointer.
-     * Each MultiIface object must have exactly one receiver thread.
-     */
-    std::thread *recvThread;
-    /**
-     * Meta information about data packets received.
-     */
-    RecvScheduler recvScheduler;
-
-  protected:
-    /**
-     * The rank of this process among the gem5 peers.
-     */
-    unsigned rank;
-    /**
-     * The number of gem5 processes comprising this multi simulation.
-     */
-    unsigned size;
-
-    bool isMaster;
-
-  private:
-    /**
-     * Total number of receiver threads (in this gem5 process).
-     * During the simulation it should be constant and equal to the
-     * number of MultiIface objects (i.e. simulated Ethernet
-     * links).
-     */
-    static unsigned recvThreadsNum;
-    /**
-     * The singleton Sync object to perform multi synchronisation.
-     */
-    static Sync *sync;
-    /**
-     * The singleton SyncEvent object to schedule periodic multi sync.
-     */
-    static SyncEvent *syncEvent;
-    /**
-     * The very first MultiIface object created becomes the master. We need
-     * a master to co-ordinate the global synchronisation.
-     */
-    static MultiIface *master;
-
-  private:
-    /**
-     * Send out a data packet to the remote end.
-     * @param header Meta info about the packet (which needs to be transferred
-     * to the destination alongside the packet).
-     * @param packet Pointer to the packet to send.
-     */
-    virtual void sendPacket(const Header &header, const EthPacketPtr &packet) = 0;
-    /**
-     * Send out a control command to the remote end.
-     * @param header Meta info describing the command (e.g. sync request)
-     */
-    virtual void sendCmd(const Header &header) = 0;
-    /**
-     * Receive a header (i.e. meta info describing a data packet or a control command)
-     * from the remote end.
-     * @param header The meta info structure to store the incoming header.
-     */
-    virtual bool recvHeader(Header &header) = 0;
-    /**
-     * Receive a packet from the remote end.
-     * @param header Meta info about the incoming packet (obtanied by a previous
-     * call to the recvHedaer() method).
-     * @param Pointer to packet received.
-     */
-    virtual void recvPacket(const Header &header, EthPacketPtr &packet) = 0;
-    /**
-     * The function executed by a receiver thread.
-     */
-    void recvThreadFunc(Event *recv_done, Tick link_delay);
-
-  public:
-
-    /**
-     * ctor
-     * @param multi_rank Rank of this gem5 process within the multi run
-     * @param sync_start Start tick for multi synchronisation
-     * @param sync_repeat Frequency for multi synchronisation
-     * @param em The event manager associated with the simulated Ethernet link
-     */
-    MultiIface(unsigned multi_rank,
-               unsigned multi_size,
-               Tick sync_start,
-               Tick sync_repeat,
-               EventManager *em,
-               bool is_switch,
-               int num_nodes);
-
-    virtual ~MultiIface();
-    /**
-     * Send out an Ethernet packet.
-     * @param pkt The Ethernet packet to send.
-     * @param send_delay The delay in ticks for the send completion event.
-     */
-    void packetOut(EthPacketPtr pkt, Tick send_delay);
-    /**
-     * Fetch the packet scheduled to be received next by the simulated
-     * network link.
-     *
-     * @note This method is called within the process() method of the link
-     * receive done event. It also schedules the next receive event if the
-     * receive queue is not empty.
-     */
-    EthPacketPtr packetIn() { return recvScheduler.popPacket(); }
-    /**
-     * spawn the receiver thread.
-     * @param recv_done The receive done event associated with the simulated
-     * Ethernet link.
-     * @param link_delay The link delay for the simulated Ethernet link.
-     */
-    void spawnRecvThread(Event *recv_done, Tick link_delay);
-
-    DrainState drain() M5_ATTR_OVERRIDE;
-    void drainResume() M5_ATTR_OVERRIDE;
-    void init();
-    void startup();
-
-    void serialize(CheckpointOut &cp) const M5_ATTR_OVERRIDE;
-    void unserialize(CheckpointIn &cp) M5_ATTR_OVERRIDE;
-    /**
-     * Initiate the exit from the simulation.
-     *
-     * @return False if we are in multi mode and a collaborative exit is
-     * initiated, True otherwise.
-     */
-    static bool readyToExit(Tick delay);
-    /**
-     * Initiate taking a checkpoint
-     *
-     * @return False if we are in multi mode and a collaborative checkpoint is
-     * initiated, True otherwise.
-     */
-    static bool readyToCkpt(Tick delay, Tick period);
-    /**
-     * Getter for the multi rank param.
-     */
-    static uint64_t rankParam();
-    /**
-     * Getter for the multi size param.
-     */
-    static uint64_t sizeParam();
- };
-
-#endif
diff --git a/src/dev/multi_packet.hh b/src/dev/multi_packet.hh
deleted file mode 100644
--- a/src/dev/multi_packet.hh
+++ /dev/null
@@ -1,106 +0,0 @@
-/*
- * Copyright (c) 2015 ARM Limited
- * All rights reserved
- *
- * The license below extends only to copyright in the software and shall
- * not be construed as granting a license to any other intellectual
- * property including but not limited to intellectual property relating
- * to a hardware implementation of the functionality of the software
- * licensed hereunder.  You may use the software subject to the license
- * terms below provided that you ensure that this notice is replicated
- * unmodified and in its entirety in all distributions of the software,
- * modified or unmodified, in source code or in binary form.
- *
- * Redistribution and use in source and binary forms, with or without
- * modification, are permitted provided that the following conditions are
- * met: redistributions of source code must retain the above copyright
- * notice, this list of conditions and the following disclaimer;
- * redistributions in binary form must reproduce the above copyright
- * notice, this list of conditions and the following disclaimer in the
- * documentation and/or other materials provided with the distribution;
- * neither the name of the copyright holders nor the names of its
- * contributors may be used to endorse or promote products derived from
- * this software without specific prior written permission.
- *
- * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
- * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
- * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
- * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
- * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
- * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
- * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
- * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
- * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
- * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
- * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
- *
- * Authors: Gabor Dozsa
- */
-
-/* @file
- * Header packet class for multi gem5 runs.
- *
- * For a high level description about multi gem5 see comments in
- * header file multi_iface.hh.
- *
- * The MultiHeaderPkt class defines the format of message headers
- * sent among gem5 processes during a multi gem5 simulation. A header packet
- * can either carry the description of data packet (i.e. a simulated Ethernet
- * packet) or a synchronisation related control command. In case of
- * data packet description, the corresponding data packet always follows
- * the header packet back-to-back.
- */
-#ifndef __DEV_MULTI_PACKET_HH__
-#define __DEV_MULTI_PACKET_HH__
-
-#include <cstring>
-
-#include "base/types.hh"
-
-class MultiHeaderPkt
-{
-  private:
-    MultiHeaderPkt() {}
-    ~MultiHeaderPkt() {}
-
-  public:
-    enum class ReqType { immediate, collective, pending, none };
-    /**
-     *  The msg type defines what informarion a multi header packet carries.
-     */
-    enum class MsgType
-    {
-        dataDescriptor,
-        cmdSyncReq,
-        cmdSyncAck,
-        unknown
-    };
-
-    struct Header
-    {
-        /**
-         * The msg type field is valid for all header packets.
-         *
-         * @note senderRank is used with data packets while collFlags are used
-         * by sync ack messages to trigger collective ckpt or exit events.
-         */
-        MsgType msgType;
-        Tick sendTick;
-        union {
-            Tick sendDelay;
-            Tick syncRepeat;
-        };
-        union {
-            /**
-             * Actual length of the simulated Ethernet packet.
-             */
-            unsigned dataPacketLength;
-            struct {
-                ReqType needCkpt;
-                ReqType needExit;
-            };
-        };
-    };
-};
-
-#endif
diff --git a/src/dev/tcp_iface.cc b/src/dev/tcp_iface.cc
--- a/src/dev/tcp_iface.cc
+++ b/src/dev/tcp_iface.cc
@@ -35,10 +35,11 @@
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  * Authors: Gabor Dozsa
+ *          Mohammad Alian
  */
 
 /* @file
- * TCP stream socket based interface class implementation for multi gem5 runs.
+ * TCP stream socket based interface class implementation for dist-gem5 runs.
  */
 
 #include "dev/tcp_iface.hh"
@@ -54,8 +55,8 @@
 #include <cstring>
 
 #include "base/types.hh"
-#include "debug/MultiEthernet.hh"
-#include "debug/MultiEthernetCmd.hh"
+#include "debug/DistEthernet.hh"
+#include "debug/DistEthernetCmd.hh"
 #include "sim/sim_exit.hh"
 
 // MSG_NOSIGNAL does not exists on OS X
@@ -72,10 +73,10 @@
 bool TCPIface::anyListening = false;
 
 TCPIface::TCPIface(string server_ip, unsigned server_port,
-                   unsigned multi_rank, unsigned multi_size,
+                   unsigned dist_rank, unsigned dist_size,
                    Tick sync_start, Tick sync_repeat,
                    EventManager *em, bool is_switch, int num_nodes) :
-    MultiIface(multi_rank, multi_size, sync_start, sync_repeat, em,
+    DistIface(dist_rank, dist_size, sync_start, sync_repeat, em,
                is_switch, num_nodes),
     port(server_port), ip(server_ip), isSwitch(is_switch), listening(false)
 {
@@ -123,7 +124,7 @@
     if (isSwitch) {
         if (isMaster) {
             while (!listen(port)) {
-                DPRINTF(MultiEthernet, "TCPIface(listen): Can't bind port %d\n"
+                DPRINTF(DistEthernet, "TCPIface(listen): Can't bind port %d\n"
                         , port);
                 port++;
             }
@@ -233,10 +234,10 @@
 void
 TCPIface::sendCmd(const Header &header)
 {
-    DPRINTF(MultiEthernetCmd, "TCPIface::sendCmd() type: %d\n",
+    DPRINTF(DistEthernetCmd, "TCPIface::sendCmd() type: %d\n",
             static_cast<int>(header.msgType));
     // Global commands (i.e. sync request) are always sent by the master
-    // MultiIface. The transfer method is simply implemented as point-to-point
+    // DistIface. The transfer method is simply implemented as point-to-point
     // messages for now
     for (auto s: sockRegistry)
         sendTCP(s, (void*)&header, sizeof(header));
@@ -246,7 +247,7 @@
 TCPIface::recvHeader(Header &header)
 {
     bool ret = recvTCP(sock, &header, sizeof(header));
-    DPRINTF(MultiEthernetCmd, "TCPIface::recvHeader() type: %d ret: %d\n",
+    DPRINTF(DistEthernetCmd, "TCPIface::recvHeader() type: %d ret: %d\n",
             static_cast<int>(header.msgType), ret);
     return ret;
 }
diff --git a/src/dev/tcp_iface.hh b/src/dev/tcp_iface.hh
--- a/src/dev/tcp_iface.hh
+++ b/src/dev/tcp_iface.hh
@@ -35,17 +35,17 @@
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  * Authors: Gabor Dozsa
+ *          Mohammad Alian
  */
 
 /* @file
- * TCP stream socket based interface class for multi gem5 runs.
+ * TCP stream socket based interface class for dist-gem5 runs.
  *
- * For a high level description about multi gem5 see comments in
- * header file multi_iface.hh.
+ * For a high level description about dist-gem5 see comments in
+ * header file dist_iface.hh.
  *
- * The TCP subclass of MultiIface uses a separate server process
- * (see tcp_server.[hh,cc] under directory gem5/util/multi). Each gem5
- * process connects to the server via a stream socket. The server process
+ * Each gem5 process connects to the server (another gem5 process which
+ * simulates a switch box) via a stream socket. The server process
  * transfers messages and co-ordinates the synchronisation among the gem5
  * peers.
  */
@@ -55,11 +55,11 @@
 
 #include <string>
 
-#include "dev/multi_iface.hh"
+#include "dev/dist_iface.hh"
 
 class EventManager;
 
-class TCPIface : public MultiIface
+class TCPIface : public DistIface
 {
   private:
     /**
@@ -126,13 +126,13 @@
      * server process.
      * @param server_port The port number the server listening for new
      * connections.
-     * @param sync_start The tick for the first multi synchronisation.
-     * @param sync_repeat The frequency of multi synchronisation.
+     * @param sync_start The tick for the first dist synchronisation.
+     * @param sync_repeat The frequency of dist synchronisation.
      * @param em The EventManager object associated with the simulated
      * Ethernet link.
      */
     TCPIface(std::string server_name, unsigned server_port,
-             unsigned multi_rank, unsigned multi_size,
+             unsigned dist_rank, unsigned dist_size,
              Tick sync_start, Tick sync_repeat, EventManager *em,
              bool is_switch, int num_nodes);
 
diff --git a/util/dist/gem5-dist.sh b/util/dist/gem5-dist.sh
new file mode 100755
--- /dev/null
+++ b/util/dist/gem5-dist.sh
@@ -0,0 +1,362 @@
+#! /bin/bash
+
+#
+# Copyright (c) 2015 ARM Limited
+# All rights reserved
+#
+# The license below extends only to copyright in the software and shall
+# not be construed as granting a license to any other intellectual
+# property including but not limited to intellectual property relating
+# to a hardware implementation of the functionality of the software
+# licensed hereunder.  You may use the software subject to the license
+# terms below provided that you ensure that this notice is replicated
+# unmodified and in its entirety in all distributions of the software,
+# modified or unmodified, in source code or in binary form.
+#
+# Copyright (c) 2015 University of Illinois Urbana Champaing
+# All rights reserved
+#
+# Redistribution and use in source and binary forms, with or without
+# modification, are permitted provided that the following conditions are
+# met: redistributions of source code must retain the above copyright
+# notice, this list of conditions and the following disclaimer;
+# redistributions in binary form must reproduce the above copyright
+# notice, this list of conditions and the following disclaimer in the
+# documentation and/or other materials provided with the distribution;
+# neither the name of the copyright holders nor the names of its
+# contributors may be used to endorse or promote products derived from
+# this software without specific prior written permission.
+#
+# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
+# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
+# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
+# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
+# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
+# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
+# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
+# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
+# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
+# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
+# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
+#
+# Authors: Gabor Dozsa
+#          Mohammad Alian
+
+
+# This is a wrapper script to run a dist gem5 simulations.
+# See the usage_func() below for hints on how to use it. Also,
+# there are some examples in the util/dist directory (e.g.
+# see util/dist/test-2nodes-AArch64.sh)
+#
+#
+# Allocated hosts/cores are assumed to be listed in the LSB_MCPU_HOSTS
+# environment variable (which is what LSF does by default).
+# E.g. LSB_MCPU_HOSTS=\"hname1 2 hname2 4\" means we have altogether 6 slots
+# allocated to launch the gem5 processes, 2 of them are on host hname1
+# and 4 of them are on host hname2.
+# If LSB_MCPU_HOSTS environment variable is not defined then we launch all
+# processes on the localhost.
+#
+# Each gem5 process are passed in a unique rank ID [0..N-1] via the kernel
+# boot params. The total number of gem5 processes is also passed in.
+# These values can be used in the boot script to configure the MAC/IP
+# addresses - among other things (see util/dist/bootscript.rcS).
+#
+# Each gem5 process will create an m5out.$GEM5_RANK directory for
+# the usual output files. Furthermore, there will be a separate log file
+# for each ssh session (we use ssh to start gem5 processes) and one for
+# the server. These are called log.$GEM5_RANK and log.switch.
+#
+
+
+# print help
+usage_func ()
+{
+    echo "Usage:$0 [-debug] [-d debug-flags] [-n nnodes] [-f fullsystem] [-s switch] [-p port] [-r rundir] [-c ckptdir] gem5_exe gem5_args"
+    echo "     -debug    : debug mode (start gem5 in gdb)"
+    echo "     debugflags: debug flags for trace based debugging"
+    echo "     nnodes    : number of gem5 processes"
+    echo "     fullsystem: fullsystem config file"
+    echo "     switch    : switch config file"
+    echo "     port      : switch listen port"
+    echo "     rundir    : run simulation under this path. If not specified, current dir will be used"
+    echo "     ckptdir   : dump/restore checkpoints to/from this path. If not specified, current dir will be used"
+    echo "     gem5_exe  : gem5 executable (full path required)"
+    echo "     gem5_args : usual gem5 arguments ( m5 options, config script options)"
+    echo "Note: if no LSF slots allocation is found all proceses are launched on the localhost."
+}
+
+
+# Process (optional) command line options
+
+while true
+do
+    case "x$1" in
+        x-n|x-nodes)
+            NNODES=$2
+            shift 2
+            ;;
+        x-d|x-debug-flags)
+            GEM5_DEBUG_FLAGS=$2
+            shift 2
+            ;;
+        x-f|x-fullsystem)
+            FS_CONFIG=$2
+            shift 2
+            ;;
+        x-s|x-switch)
+            SWITCH_CONFIG=$2
+            shift 2
+            ;;
+        x-p|x-port)
+            SWITCH_PORT=$2
+            shift 2
+            ;;
+        x-debug)
+            GEM5_DEBUG="-debug"
+            shift 1
+            ;;
+        x-r|x-rundir)
+            RUN_DIR=$2
+            shift 2
+            ;;
+        x-c|x-ckptdir)
+            CKPT_DIR=$2
+            shift 2
+            ;;
+        *)
+            break
+            ;;
+    esac
+done
+
+# The remaining command line args must be the usual gem5 command
+(($# < 2)) && { usage_func; exit -1; }
+GEM5_EXE=$1
+shift
+GEM5_ARGS="$*"
+
+# Default values to use (in case they are not defined as command line options)
+DEFAULT_FS_CONFIG=$M5_PATH/configs/example/fs.py
+DEFAULT_SWITCH_CONFIG=$M5_PATH/configs/example/sw.py
+DEFAULT_SWITCH_PORT=2200
+
+[ -z "$FS_CONFIG" ]  && FS_CONFIG=$DEFAULT_FS_CONFIG
+[ -z "$SWITCH_CONFIG" ]  && SWITCH_CONFIG=$DEFAULT_SWITCH_CONFIG
+[ -z "$SWITCH_PORT" ] && SWITCH_PORT=$DEFAULT_SWITCH_PORT
+[ -z "$NNODES" ]      && NNODES=2
+[ -z "$RUN_DIR" ]      && RUN_DIR=$(pwd)
+[ -z "$CKPT_DIR" ]      && CKPT_DIR=$(pwd)
+! [ -z "$GEM5_DEBUG_FLAGS" ] && GEM5_DEBUG_FLAGS="--debug-flags=$GEM5_DEBUG_FLAGS"
+
+#  Check if all the executables we need exist
+[ -f "$FS_CONFIG" ] || { echo "Switch config ${FS_CONFIG} not found"; exit 1; }
+[ -f "$SWITCH_CONFIG" ] || { echo "Switch config ${SWITCH_CONFIG} not found"; exit 1; }
+[ -x "$GEM5_EXE" ]   || { echo "Executable ${GEM5_EXE} not found"; exit 1; }
+# make sure that RUN_DIR exists
+mkdir -p $RUN_DIR > /dev/null 2>&1 
+
+declare -a SSH_PIDS
+declare -a HOSTS
+declare -a NCORES
+
+# Find out which cluster hosts/slots are allocated or
+# use localhost if there is no LSF allocation.
+# We assume that allocated slots are listed in the LSB_MCPU_HOSTS
+# environment variable in the form:
+# host1 nslots1 host2 nslots2 ...
+# (This is what LSF does by default.)
+NH=0
+[ "x$LSB_MCPU_HOSTS" != "x" ] || LSB_MCPU_HOSTS="127.0.0.1 $NNODES"
+host=""
+for hc in $LSB_MCPU_HOSTS
+do
+    if [ "x$host" == "x" ]
+    then
+        host=$hc
+        HOSTS+=($hc)
+    else
+        NCORES+=($hc)
+        ((NH+=hc))
+        host=""
+    fi
+done
+((NNODES==NH)) || { echo "(E) Number of cluster slots ($NH) and gem5 instances ($N) differ"; exit -1; }
+#echo "hosts: ${HOSTS[@]}"
+#echo "hosts: ${NCORES[@]}"
+#echo ${#HOSTS[@]}
+
+
+# function to clean up and abort if something goes wrong
+abort_func ()
+{
+    echo
+    echo "KILLED $(date)"
+    # Try to Kill the server first. That should trigger an exit for all connected
+    # gem5 processes.
+    [ "x$SWITCH_PID" != "x" ] && kill $SWITCH_PID 2>/dev/null
+    sleep 20
+    # (try to) kill gem5 processes - just in case something went wrong with the
+    # server triggered exit
+    bname=$(basename $GEM5_EXE)
+    killall -q -s SIGKILL $bname
+    for h in ${HOSTS[@]}
+    do
+	ssh $h killall -q -s SIGKILL $bname
+    done
+    sleep 5
+    # kill the watchdog
+    [ "x$WATCHDOG_PID" != "x" ] && kill $WATCHDOG_PID 2>/dev/null
+    exit -1
+}
+
+
+# We need a watchdog to trigger full clean up if a gem5 process dies
+watchdog_func ()
+{
+    while true
+    do
+        sleep 30
+        ((NDEAD=0))
+        for p in ${SSH_PIDS[*]}
+        do
+            kill -0 $p 2>/dev/null || ((NDEAD+=1))
+        done
+        kill -0 $SWITCH_PID || ((NDEAD+=1))
+        if ((NDEAD>0))
+        then
+            # we may be in the middle of an orderly termination,
+            # give it some time to complete before reporting abort
+            sleep 60
+            echo -n "(I) (some) gem5 process(es) exited"
+            abort_func
+        fi
+    done
+}
+
+# This function launches the gem5 processes. The only purpose is to enable
+# launching gem5 processes under gdb control for debugging
+start_func ()
+{
+      local N=$1
+      local HOST=$2
+      local ENV_ARGS=$3
+      shift 3
+      if [ "x$GEM5_DEBUG" != "x" ]
+      then
+	      echo "DEBUG starting terminal..."
+	      MY_ARGS="$@"
+	      xterm -e "gdb --args $MY_ARGS" &
+      else
+        ssh $HOST $ENV_ARGS "$@" &> $RUN_DIR/log.$N &
+      fi
+}
+
+# block till the gem5 process starts
+connected ()
+{
+    FILE=$1
+    STRING=$2
+    echo -n "waiting for $3 to start "
+    while : ;
+    do
+        kill -0 $4 || { echo "Failed to start $3"; exit -1; }
+        [[ -f "$FILE" ]] &&                                                   \
+        grep -q "$STRING" "$FILE" &&                                          \
+        echo -e "\nnode #$3 started" &&                                       \
+        break
+
+        sleep 2
+        echo -n "."
+    done
+}
+
+# Trigger full clean up in case we are being killed by external signal
+trap 'abort_func' INT TERM
+
+# env args to be passed explicitly to gem5 processes started via ssh
+ENV_ARGS="LD_LIBRARY_PATH=$LD_LIBRARY_PATH M5_PATH=$M5_PATH"
+
+#cleanup log files before starting gem5 processes
+rm $RUN_DIR/log.switch > /dev/null 2>&1
+
+# make sure that CKPT_DIR exists
+mkdir -p $CKPT_DIR/m5out.switch > /dev/null 2>&1 
+# launch switch gem5
+echo "launch switch gem5 process ..."
+$GEM5_EXE -d $RUN_DIR/m5out.switch                                            \
+             $GEM5_DEBUG_FLAGS                                                \
+             $SWITCH_CONFIG                                                   \
+             $GEM5_ARGS                                                       \
+             --checkpoint-dir=$CKPT_DIR/m5out.switch                          \
+             --is-switch                                                      \
+             --dist-size=$NNODES                                              \
+             --dist-server-port=$SWITCH_PORT &> $RUN_DIR/log.switch &
+SWITCH_PID=$!
+
+# block here till switch process starts
+connected $RUN_DIR/log.switch "tcp_iface listening on port" "switch" $SWITCH_PID
+LINE=$(grep -r "tcp_iface listening on port" $RUN_DIR/log.switch)
+
+IFS=' ' read -ra ADDR <<< "$LINE"
+# acutal port that switch is listening on may be different 
+# from what we specified if the port was busy
+SWITCH_PORT=${ADDR[5]}
+
+# Now launch all the gem5 processes with ssh.
+echo "START $(date)"
+n=0
+for ((i=0; i < ${#HOSTS[@]}; i++))
+do
+    h=${HOSTS[$i]}
+    for ((j=0; j < ${NCORES[i]}; j++))
+    do
+        #cleanup log files before starting gem5 processes
+        rm $RUN_DIR/log.$n > /dev/null 2>&1
+        # make sure that CKPT_DIR exists
+        mkdir -p $CKPT_DIR/m5out.$n > /dev/null 2>&1
+	    echo "starting gem5 on $h ..."
+	    start_func $n $h "$ENV_ARGS" $GEM5_EXE -d $RUN_DIR/m5out.$n           \
+        $GEM5_DEBUG_FLAGS                                                     \
+        $FS_CONFIG                                                            \
+        $GEM5_ARGS                                                            \
+        --checkpoint-dir=$CKPT_DIR/m5out.$n                                   \
+	    --dist                                                                \
+	    --dist-rank=$n                                                        \
+	    --dist-size=$NNODES                                                   \
+        --dist-server-name=${HOSTS[0]}                                        \
+        --dist-server-port=$SWITCH_PORT
+	    SSH_PIDS[$n]=$!
+        if [ "x$GEM5_DEBUG" == "x" ]
+        then
+            connected $RUN_DIR/log.$n "Listening" $j ${SSH_PIDS[$n]}
+        fi
+	    ((n+=1))
+    done
+done
+
+# Wait here if it is a debug session
+[ "x$GEM5_DEBUG" == "x" ] || {  echo "DEBUG session"; wait $SWITCH_PID; exit -1; }
+
+# start watchdog to trigger complete abort (after a grace period) if any
+# gem5 process dies
+watchdog_func &
+WATCHDOG_PID=$!
+
+# wait for exit statuses
+((NFAIL=0))
+for p in ${SSH_PIDS[*]}
+do
+    wait $p || ((NFAIL+=1))
+done
+wait $SWITCH_PID || ((NFAIL+=1))
+
+# all done, let's terminate the watchdog
+kill $WATCHDOG_PID 2>/dev/null
+
+if ((NFAIL==0))
+then
+    echo "EXIT $(date)"
+else
+    echo "ABORT $(date)"
+fi
diff --git a/util/dist/test/bootscript.rcS b/util/dist/test/bootscript.rcS
new file mode 100644
--- /dev/null
+++ b/util/dist/test/bootscript.rcS
@@ -0,0 +1,153 @@
+#!/bin/bash
+
+
+#
+# Copyright (c) 2015 ARM Limited
+# All rights reserved
+#
+# The license below extends only to copyright in the software and shall
+# not be construed as granting a license to any other intellectual
+# property including but not limited to intellectual property relating
+# to a hardware implementation of the functionality of the software
+# licensed hereunder.  You may use the software subject to the license
+# terms below provided that you ensure that this notice is replicated
+# unmodified and in its entirety in all distributions of the software,
+# modified or unmodified, in source code or in binary form.
+#
+# Copyright (c) 2015 University of Illinois Urbana Champaing
+# All rights reserved
+#
+# Redistribution and use in source and binary forms, with or without
+# modification, are permitted provided that the following conditions are
+# met: redistributions of source code must retain the above copyright
+# notice, this list of conditions and the following disclaimer;
+# redistributions in binary form must reproduce the above copyright
+# notice, this list of conditions and the following disclaimer in the
+# documentation and/or other materials provided with the distribution;
+# neither the name of the copyright holders nor the names of its
+# contributors may be used to endorse or promote products derived from
+# this software without specific prior written permission.
+#
+# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
+# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
+# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
+# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
+# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
+# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
+# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
+# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
+# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
+# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
+# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
+#
+# Authors: Gabor Dozsa
+#          Mohammad Alian
+#
+#
+# This is an example boot script to use for dist-gem5 runs. The important
+# task here is to extract the rank and size information through the m5
+# initparam utility and use those to configure MAC/IP addresses and hostname.
+#
+# You are expected to customize this scipt for your needs (e.g. change
+# the command at the end of the scipt to run your tests/workloads.
+
+source /root/.bashrc
+echo "bootscript.rcS is running"
+
+# Retrieve dist-gem5 rank and size parameters using magic keys
+MY_RANK=$(/sbin/m5 initparam 1234)
+[ $? = 0 ] || { echo "m5 initparam failed"; exit -1; }
+MY_SIZE=$(/sbin/m5 initparam 1235)
+[ $? = 0 ] || { echo "m5 initparam failed"; exit -1; }
+
+
+echo "***** Start boot script! *****"
+if [ "${RUNSCRIPT_VAR+set}" != set ]
+then
+    # Signal our future self that it's safe to continue
+    echo "RUNSCRIPT_VAR not set! Setting it ..."
+    export RUNSCRIPT_VAR=1
+else
+    if [ "$MY_RANK" == "0" ]
+    then
+        # We've already executed once, so we should exit
+        echo "calling m5 exit!"
+        /sbin/m5 exit
+    else
+        echo "Else part - RUNSCRIPT_VAR1_TUX1 is set! So reload and execute!"
+        echo "Else part - Loading new script..."
+        /sbin/m5 readfile > /tmp/runscript1.sh
+        chmod 755 /tmp/runscript1.sh
+
+        # Execute the new runscript
+        if [ -s /tmp/runscript1.sh ]
+        then
+            #/system/bin/sh /data/runscript1.sh
+            echo "Else part - executing newly loaded script ...!"
+            /bin/bash /tmp/runscript1.sh
+        else 
+            echo "Else part - Script not specified."
+            echo "Else part - Exiting..." 
+            /sbin/m5 exit
+        fi
+    fi
+fi
+
+/bin/hostname node${MY_RANK}
+
+# Keep MAC address assignment simple for now ...
+(($MY_RANK > 97)) && { echo "(E) Rank must be less than 98"; /sbin/m5 abort; }
+((MY_ADDR = MY_RANK + 2))
+if (($MY_ADDR < 10))
+then
+    MY_ADDR_PADDED=0${MY_ADDR}
+else
+    MY_ADDR_PADDED=${MY_ADDR}
+fi
+
+/sbin/ifconfig eth0 hw ether 00:90:00:00:00:${MY_ADDR_PADDED}
+/sbin/ifconfig eth0 192.168.0.${MY_ADDR} netmask 255.255.255.0 up
+
+/sbin/ifconfig -a
+
+echo "Hello from $MY_RANK of $MY_SIZE"
+
+
+if [ "$MY_RANK" == "0" ]
+then
+    # Trigger an immediate checkpoint at the next sync (by passing a non-zero
+    # delay param to m5 ckpt)
+    /sbin/m5 checkpoint 1
+else
+    # do nothing, just iterate through the script
+    echo "do nothing, just iterate through the script ..."
+fi
+
+#THIS IS WHERE EXECUTION BEGINS FROM AFTER RESTORING FROM CKPT
+if [ "$RUNSCRIPT_VAR" -eq 1 ]
+then
+
+    # Signal our future self not to recurse infinitely
+    export RUNSCRIPT_VAR=2
+    echo "3. RUNSCRIPT_VAR is $RUNSCRIPT_VAR"
+
+    # Read the script for the checkpoint restored execution
+    echo "Loading new script..."
+    /sbin/m5 readfile > /tmp/runscript1.sh
+    chmod 755 /tmp/runscript1.sh
+
+    # Execute the new runscript
+    if [ -s /tmp/runscript1.sh ]
+    then
+        #/system/bin/sh /data/runscript1.sh
+        echo "executing newly loaded script ..."
+        /bin/bash /tmp/runscript1.sh
+
+    else
+        echo "Script not specified. Dropping into shell..."
+    fi
+
+fi
+
+echo "Fell through script. Exiting..."
+/sbin/m5 exit
diff --git a/util/dist/test/test-2nodes-AArch64.sh b/util/dist/test/test-2nodes-AArch64.sh
new file mode 100755
--- /dev/null
+++ b/util/dist/test/test-2nodes-AArch64.sh
@@ -0,0 +1,79 @@
+#! /bin/bash
+
+#
+# Copyright (c) 2015 ARM Limited
+# All rights reserved
+#
+# The license below extends only to copyright in the software and shall
+# not be construed as granting a license to any other intellectual
+# property including but not limited to intellectual property relating
+# to a hardware implementation of the functionality of the software
+# licensed hereunder.  You may use the software subject to the license
+# terms below provided that you ensure that this notice is replicated
+# unmodified and in its entirety in all distributions of the software,
+# modified or unmodified, in source code or in binary form.
+#
+# Redistribution and use in source and binary forms, with or without
+# modification, are permitted provided that the following conditions are
+# met: redistributions of source code must retain the above copyright
+# notice, this list of conditions and the following disclaimer;
+# redistributions in binary form must reproduce the above copyright
+# notice, this list of conditions and the following disclaimer in the
+# documentation and/or other materials provided with the distribution;
+# neither the name of the copyright holders nor the names of its
+# contributors may be used to endorse or promote products derived from
+# this software without specific prior written permission.
+#
+# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
+# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
+# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
+# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
+# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
+# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
+# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
+# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
+# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
+# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
+# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
+#
+# Authors: Gabor Dozsa
+#
+#
+# This is an example script to start a dist gem5 simulations using
+# two AArch64 systems. It is also uses the example
+# dist gem5 bootscript util/dist/test/bootscript.rcS that will run the
+# linux ping command to check if we can see the peer system connected via
+# the simulated Ethernet link.
+
+GEM5_DIR=$(pwd)/$(dirname $0)/../../..
+
+#M5_PATH=$HOME/GEM5/public_dist
+#export M5_PATH
+
+
+
+IMG=$M5_PATH/disks/aarch64-ubuntu-trusty-headless.img
+VMLINUX=$M5_PATH/binaries/vmlinux.aarch64.20140821
+DTB=$M5_PATH/binaries/vexpress.aarch64.20140821.dtb
+
+SYS_CONFIG=$GEM5_DIR/configs/example/fs.py
+#SYS_CONFIG=$HOME/GEM5/BRANDNEW/gem5-obj/configs/hpc/RealViewHPC.py
+GEM5_EXE=$GEM5_DIR/build/ARM/gem5.opt
+
+BOOT_SCRIPT=$GEM5_DIR/util/dist/test/bootscript.rcS
+GEM5_DIST_SH=$GEM5_DIR/util/dist/gem5-dist.sh
+
+DEBUG_FLAGS="-d DistEthernet,DistEthernetPkt"
+#CHKPT_RESTORE="-r1"
+
+NNODES=2
+
+$GEM5_DIST_SH $DEBUG_FLAGS -n $NNODES -f $SYS_CONFIG $GEM5_EXE   \
+    --cpu-type=atomic                                          \
+    --num-cpus=1                                               \
+    --machine-type=VExpress_EMM64                              \
+    --disk-image=$IMG                                          \
+    --kernel=$VMLINUX                                          \
+    --dtb-filename=$DTB                                        \
+    --script=$BOOT_SCRIPT                                      \
+    $CHKPT_RESTORE
diff --git a/util/multi/Makefile b/util/multi/Makefile
deleted file mode 100644
--- a/util/multi/Makefile
+++ /dev/null
@@ -1,63 +0,0 @@
-#
-# Copyright (c) 2015 ARM Limited
-# All rights reserved
-#
-# The license below extends only to copyright in the software and shall
-# not be construed as granting a license to any other intellectual
-# property including but not limited to intellectual property relating
-# to a hardware implementation of the functionality of the software
-# licensed hereunder.  You may use the software subject to the license
-# terms below provided that you ensure that this notice is replicated
-# unmodified and in its entirety in all distributions of the software,
-# modified or unmodified, in source code or in binary form.
-#
-# Redistribution and use in source and binary forms, with or without
-# modification, are permitted provided that the following conditions are
-# met: redistributions of source code must retain the above copyright
-# notice, this list of conditions and the following disclaimer;
-# redistributions in binary form must reproduce the above copyright
-# notice, this list of conditions and the following disclaimer in the
-# documentation and/or other materials provided with the distribution;
-# neither the name of the copyright holders nor the names of its
-# contributors may be used to endorse or promote products derived from
-# this software without specific prior written permission.
-#
-# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
-# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
-# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
-# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
-# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
-# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
-# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-#
-# Authors: Gabor Dozsa
-
-CXX= g++
-
-DEBUG= -DDEBUG
-
-M5_ARCH?= ARM
-M5_DIR?= ../..
-
-vpath % $(M5_DIR)/build/$(M5_ARCH)/dev
-
-INCDIRS= -I. -I$(M5_DIR)/build/$(M5_ARCH) -I$(M5_DIR)/ext
-CCFLAGS= -g -Wall -O3 $(DEBUG) -std=c++11 -MMD $(INCDIRS)
-
-default: tcp_server
-
-clean:
-	@rm -f tcp_server *.o *.d *~
-
-tcp_server: tcp_server.o multi_packet.o
-	$(CXX) $(LFLAGS) -o $@ $^
-
-%.o: %.cc
-	@echo '$(CXX) $(CCFLAGS) -c $(notdir $<) -o $@'
-	@$(CXX) $(CCFLAGS) -c $< -o $@
-
--include *.d
diff --git a/util/multi/gem5-multi.sh b/util/multi/gem5-multi.sh
deleted file mode 100755
--- a/util/multi/gem5-multi.sh
+++ /dev/null
@@ -1,357 +0,0 @@
-#! /bin/bash
-
-#
-# Copyright (c) 2015 ARM Limited
-# All rights reserved
-#
-# The license below extends only to copyright in the software and shall
-# not be construed as granting a license to any other intellectual
-# property including but not limited to intellectual property relating
-# to a hardware implementation of the functionality of the software
-# licensed hereunder.  You may use the software subject to the license
-# terms below provided that you ensure that this notice is replicated
-# unmodified and in its entirety in all distributions of the software,
-# modified or unmodified, in source code or in binary form.
-#
-# Redistribution and use in source and binary forms, with or without
-# modification, are permitted provided that the following conditions are
-# met: redistributions of source code must retain the above copyright
-# notice, this list of conditions and the following disclaimer;
-# redistributions in binary form must reproduce the above copyright
-# notice, this list of conditions and the following disclaimer in the
-# documentation and/or other materials provided with the distribution;
-# neither the name of the copyright holders nor the names of its
-# contributors may be used to endorse or promote products derived from
-# this software without specific prior written permission.
-#
-# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
-# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
-# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
-# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
-# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
-# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
-# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-#
-# Authors: Gabor Dozsa
-
-
-# This is a wrapper script to run a multi gem5 simulations.
-# See the usage_func() below for hints on how to use it. Also,
-# there are some examples in the util/multi directory (e.g.
-# see util/multi/test-2nodes-AArch64.sh)
-#
-#
-# Allocated hosts/cores are assumed to be listed in the LSB_MCPU_HOSTS
-# environment variable (which is what LSF does by default).
-# E.g. LSB_MCPU_HOSTS=\"hname1 2 hname2 4\" means we have altogether 6 slots
-# allocated to launch the gem5 processes, 2 of them are on host hname1
-# and 4 of them are on host hname2.
-# If LSB_MCPU_HOSTS environment variable is not defined then we launch all
-# processes on the localhost.
-#
-# Each gem5 process are passed in a unique rank ID [0..N-1] via the kernel
-# boot params. The total number of gem5 processes is also passed in.
-# These values can be used in the boot script to configure the MAC/IP
-# addresses - among other things (see util/multi/bootscript.rcS).
-#
-# Each gem5 process will create an m5out.$GEM5_RANK directory for
-# the usual output files. Furthermore, there will be a separate log file
-# for each ssh session (we use ssh to start gem5 processes) and one for
-# the server. These are called log.$GEM5_RANK and log.switch.
-#
-
-
-# print help
-usage_func ()
-{
-    echo "Usage:$0 [-debug] [-d debug-flags] [-n nnodes] [-f fullsystem] [-s switch] [-p port] [-r rundir] [-c ckptdir] gem5_exe gem5_args"
-    echo "     -debug    : debug mode (start gem5 in gdb)"
-    echo "     debugflags: debug flags for trace based debugging"
-    echo "     nnodes    : number of gem5 processes"
-    echo "     fullsystem: fullsystem config file"
-    echo "     switch    : switch config file"
-    echo "     port      : switch listen port"
-    echo "     rundir    : run simulation under this path. If not specified, current dir will be used"
-    echo "     ckptdir   : dump/restore checkpoints to/from this path. If not specified, current dir will be used"
-    echo "     gem5_exe  : gem5 executable (full path required)"
-    echo "     gem5_args : usual gem5 arguments ( m5 options, config script options)"
-    echo "Note: if no LSF slots allocation is found all proceses are launched on the localhost."
-}
-
-
-# Process (optional) command line options
-
-while true
-do
-    case "x$1" in
-        x-n|x-nodes)
-            NNODES=$2
-            shift 2
-            ;;
-        x-d|x-debug-flags)
-            GEM5_DEBUG_FLAGS=$2
-            shift 2
-            ;;
-        x-f|x-fullsystem)
-            FS_CONFIG=$2
-            shift 2
-            ;;
-        x-s|x-switch)
-            SWITCH_CONFIG=$2
-            shift 2
-            ;;
-        x-p|x-port)
-            SWITCH_PORT=$2
-            shift 2
-            ;;
-        x-debug)
-            GEM5_DEBUG="-debug"
-            shift 1
-            ;;
-        x-r|x-rundir)
-            RUN_DIR=$2
-            shift 2
-            ;;
-        x-c|x-ckptdir)
-            CKPT_DIR=$2
-            shift 2
-            ;;
-        *)
-            break
-            ;;
-    esac
-done
-
-# The remaining command line args must be the usual gem5 command
-(($# < 2)) && { usage_func; exit -1; }
-GEM5_EXE=$1
-shift
-GEM5_ARGS="$*"
-
-# Default values to use (in case they are not defined as command line options)
-DEFAULT_FS_CONFIG=$M5_PATH/configs/example/fs.py
-DEFAULT_SWITCH_CONFIG=$M5_PATH/configs/example/sw.py
-DEFAULT_SWITCH_PORT=2200
-
-[ -z "$FS_CONFIG" ]  && FS_CONFIG=$DEFAULT_FS_CONFIG
-[ -z "$SWITCH_CONFIG" ]  && SWITCH_CONFIG=$DEFAULT_SWITCH_CONFIG
-[ -z "$SWITCH_PORT" ] && SWITCH_PORT=$DEFAULT_SWITCH_PORT
-[ -z "$NNODES" ]      && NNODES=2
-[ -z "$RUN_DIR" ]      && RUN_DIR=$(pwd)
-[ -z "$CKPT_DIR" ]      && CKPT_DIR=$(pwd)
-! [ -z "$GEM5_DEBUG_FLAGS" ] && GEM5_DEBUG_FLAGS="--debug-flags=$GEM5_DEBUG_FLAGS"
-
-#  Check if all the executables we need exist
-[ -f "$FS_CONFIG" ] || { echo "Switch config ${FS_CONFIG} not found"; exit 1; }
-[ -f "$SWITCH_CONFIG" ] || { echo "Switch config ${SWITCH_CONFIG} not found"; exit 1; }
-[ -x "$GEM5_EXE" ]   || { echo "Executable ${GEM5_EXE} not found"; exit 1; }
-# make sure that RUN_DIR exists
-mkdir -p $RUN_DIR > /dev/null 2>&1 
-
-declare -a SSH_PIDS
-declare -a HOSTS
-declare -a NCORES
-
-# Find out which cluster hosts/slots are allocated or
-# use localhost if there is no LSF allocation.
-# We assume that allocated slots are listed in the LSB_MCPU_HOSTS
-# environment variable in the form:
-# host1 nslots1 host2 nslots2 ...
-# (This is what LSF does by default.)
-NH=0
-[ "x$LSB_MCPU_HOSTS" != "x" ] || LSB_MCPU_HOSTS="127.0.0.1 $NNODES"
-host=""
-for hc in $LSB_MCPU_HOSTS
-do
-    if [ "x$host" == "x" ]
-    then
-        host=$hc
-        HOSTS+=($hc)
-    else
-        NCORES+=($hc)
-        ((NH+=hc))
-        host=""
-    fi
-done
-((NNODES==NH)) || { echo "(E) Number of cluster slots ($NH) and gem5 instances ($N) differ"; exit -1; }
-#echo "hosts: ${HOSTS[@]}"
-#echo "hosts: ${NCORES[@]}"
-#echo ${#HOSTS[@]}
-
-
-# function to clean up and abort if something goes wrong
-abort_func ()
-{
-    echo
-    echo "KILLED $(date)"
-    # Try to Kill the server first. That should trigger an exit for all connected
-    # gem5 processes.
-    [ "x$SWITCH_PID" != "x" ] && kill $SWITCH_PID 2>/dev/null
-    sleep 20
-    # (try to) kill gem5 processes - just in case something went wrong with the
-    # server triggered exit
-    bname=$(basename $GEM5_EXE)
-    killall -q -s SIGKILL $bname
-    for h in ${HOSTS[@]}
-    do
-	ssh $h killall -q -s SIGKILL $bname
-    done
-    sleep 5
-    # kill the watchdog
-    [ "x$WATCHDOG_PID" != "x" ] && kill $WATCHDOG_PID 2>/dev/null
-    exit -1
-}
-
-
-# We need a watchdog to trigger full clean up if a gem5 process dies
-watchdog_func ()
-{
-    while true
-    do
-        sleep 30
-        ((NDEAD=0))
-        for p in ${SSH_PIDS[*]}
-        do
-            kill -0 $p 2>/dev/null || ((NDEAD+=1))
-        done
-        kill -0 $SWITCH_PID || ((NDEAD+=1))
-        if ((NDEAD>0))
-        then
-            # we may be in the middle of an orderly termination,
-            # give it some time to complete before reporting abort
-            sleep 60
-            echo -n "(I) (some) gem5 process(es) exited"
-            abort_func
-        fi
-    done
-}
-
-# This function launches the gem5 processes. The only purpose is to enable
-# launching gem5 processes under gdb control for debugging
-start_func ()
-{
-      local N=$1
-      local HOST=$2
-      local ENV_ARGS=$3
-      shift 3
-      if [ "x$GEM5_DEBUG" != "x" ]
-      then
-	      echo "DEBUG starting terminal..."
-	      MY_ARGS="$@"
-	      xterm -e "gdb --args $MY_ARGS" &
-      else
-        ssh $HOST $ENV_ARGS "$@" &> $RUN_DIR/log.$N &
-      fi
-}
-
-connected ()
-{
-    FILE=$1
-    STRING=$2
-    echo -n "waiting for $3 to start "
-    while : ;
-    do
-        kill -0 $4 || { echo "Failed to start $3"; exit -1; }
-        [[ -f "$FILE" ]] &&                                                   \
-        grep -q "$STRING" "$FILE" &&                                          \
-        echo -e "\nnode #$3 started" &&                                       \
-        break
-
-        sleep 2
-        echo -n "."
-    done
-}
-
-# Trigger full clean up in case we are being killed by external signal
-trap 'abort_func' INT TERM
-
-# env args to be passed explicitly to gem5 processes started via ssh
-ENV_ARGS="LD_LIBRARY_PATH=$LD_LIBRARY_PATH M5_PATH=$M5_PATH"
-
-#cleanup log files before starting gem5 processes
-rm $RUN_DIR/log.switch > /dev/null 2>&1
-
-# make sure that CKPT_DIR exists
-mkdir -p $CKPT_DIR/m5out.switch > /dev/null 2>&1 
-# launch switch gem5
-echo "launch switch gem5 process ..."
-$GEM5_EXE -d $RUN_DIR/m5out.switch                                            \
-             $GEM5_DEBUG_FLAGS                                                \
-             $SWITCH_CONFIG                                                   \
-             $GEM5_ARGS                                                       \
-             --checkpoint-dir=$CKPT_DIR/m5out.switch                          \
-             --is-switch                                                      \
-             --multi-size=$NNODES                                             \
-             --multi-server-port=$SWITCH_PORT &> $RUN_DIR/log.switch &
-SWITCH_PID=$!
-
-# block here till switch process starts
-connected $RUN_DIR/log.switch "tcp_iface listening on port" "switch" $SWITCH_PID
-LINE=$(grep -r "tcp_iface listening on port" $RUN_DIR/log.switch)
-
-IFS=' ' read -ra ADDR <<< "$LINE"
-# acutal port that switch is listening on may be different 
-# from what we specified if the port was busy
-SWITCH_PORT=${ADDR[5]}
-
-# Now launch all the gem5 processes with ssh.
-echo "START $(date)"
-n=0
-for ((i=0; i < ${#HOSTS[@]}; i++))
-do
-    h=${HOSTS[$i]}
-    for ((j=0; j < ${NCORES[i]}; j++))
-    do
-        #cleanup log files before starting gem5 processes
-        rm $RUN_DIR/log.$n > /dev/null 2>&1
-        # make sure that CKPT_DIR exists
-        mkdir -p $CKPT_DIR/m5out.$n > /dev/null 2>&1
-	    echo "starting gem5 on $h ..."
-	    start_func $n $h "$ENV_ARGS" $GEM5_EXE -d $RUN_DIR/m5out.$n           \
-        $GEM5_DEBUG_FLAGS                                                     \
-        $FS_CONFIG                                                            \
-        $GEM5_ARGS                                                            \
-        --checkpoint-dir=$CKPT_DIR/m5out.$n                                   \
-	    --multi                                                               \
-	    --multi-rank=$n                                                       \
-	    --multi-size=$NNODES                                                  \
-        --multi-server-name=${HOSTS[0]}                                       \
-        --multi-server-port=$SWITCH_PORT
-	    SSH_PIDS[$n]=$!
-        if [ "x$GEM5_DEBUG" == "x" ]
-        then
-            connected $RUN_DIR/log.$n "Listening" $j ${SSH_PIDS[$n]}
-        fi
-	    ((n+=1))
-    done
-done
-
-# Wait here if it is a debug session
-[ "x$GEM5_DEBUG" == "x" ] || {  echo "DEBUG session"; wait $SWITCH_PID; exit -1; }
-
-# start watchdog to trigger complete abort (after a grace period) if any
-# gem5 process dies
-watchdog_func &
-WATCHDOG_PID=$!
-
-# wait for exit statuses
-((NFAIL=0))
-for p in ${SSH_PIDS[*]}
-do
-    wait $p || ((NFAIL+=1))
-done
-wait $SWITCH_PID || ((NFAIL+=1))
-
-# all done, let's terminate the watchdog
-kill $WATCHDOG_PID 2>/dev/null
-
-if ((NFAIL==0))
-then
-    echo "EXIT $(date)"
-else
-    echo "ABORT $(date)"
-fi
diff --git a/util/multi/tcp_server.cc b/util/multi/tcp_server.cc
deleted file mode 100644
--- a/util/multi/tcp_server.cc
+++ /dev/null
@@ -1,517 +0,0 @@
-/*
- * Copyright (c) 2015 ARM Limited
- * All rights reserved
- *
- * The license below extends only to copyright in the software and shall
- * not be construed as granting a license to any other intellectual
- * property including but not limited to intellectual property relating
- * to a hardware implementation of the functionality of the software
- * licensed hereunder.  You may use the software subject to the license
- * terms below provided that you ensure that this notice is replicated
- * unmodified and in its entirety in all distributions of the software,
- * modified or unmodified, in source code or in binary form.
- *
- * Copyright (c) 2008 The Regents of The University of Michigan
- * All rights reserved.
- *
- * Redistribution and use in source and binary forms, with or without
- * modification, are permitted provided that the following conditions are
- * met: redistributions of source code must retain the above copyright
- * notice, this list of conditions and the following disclaimer;
- * redistributions in binary form must reproduce the above copyright
- * notice, this list of conditions and the following disclaimer in the
- * documentation and/or other materials provided with the distribution;
- * neither the name of the copyright holders nor the names of its
- * contributors may be used to endorse or promote products derived from
- * this software without specific prior written permission.
- *
- * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
- * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
- * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
- * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
- * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
- * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
- * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
- * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
- * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
- * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
- * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
- *
- * Authors: Gabor Dozsa
- */
-
-
-/* @file
- *  Message server implementation using TCP stream sockets for parallel gem5
- * runs.
- */
-#include <arpa/inet.h>
-#include <sys/socket.h>
-#include <sys/types.h>
-#include <unistd.h>
-
-#include <csignal>
-#include <cstdio>
-#include <cstdlib>
-#include <limits>
-
-#include "tcp_server.hh"
-
-using namespace std;
-
-// Some basic macros for information and error reporting.
-#define PRINTF(...) fprintf(stderr, __VA_ARGS__)
-
-#ifdef DEBUG
-static bool debugSetup = true;
-static bool debugPeriodic = false;
-static bool debugSync = true;
-static bool debugPkt = false;
-#define DPRINTF(v,...) if (v) PRINTF(__VA_ARGS__)
-#else
-#define DPRINTF(v,...)
-#endif
-
-#define inform(...) do { PRINTF("info: ");      \
-        PRINTF(__VA_ARGS__); } while(0)
-
-#define panic(...)  do { PRINTF("panic: ");     \
-        PRINTF(__VA_ARGS__);                    \
-        PRINTF("\n[%s:%s], line %d\n",          \
-               __FUNCTION__, __FILE__, __LINE__); \
-        exit(-1); } while(0)
-
-TCPServer *TCPServer::instance = nullptr;
-
-TCPServer::Channel::Channel() :
-    fd(-1), isSync(false), connected(false), needExit(false), needCkpt(false)
-{
-    MultiHeaderPkt::clearAddress(address);
-    newAddress.second = false;
-}
-
-unsigned
-TCPServer::Channel::recvRaw(void *buf, unsigned size) const
-{
-    ssize_t n;
-    // This is a blocking receive.
-    n = recv(fd, buf, size, MSG_WAITALL);
-
-    if (n < 0)
-        panic("read() failed:%s", strerror(errno));
-    else if (n > 0 && n < size)
-        // the recv() call should wait for the full message
-        panic("read() failed");
-
-    return n;
-}
-
-void
-TCPServer::Channel::sendRaw(const void *buf, unsigned size) const
-{
-    ssize_t n;
-    n = send(fd, buf, size, MSG_NOSIGNAL);
-    if (n < 0)
-        panic("write() failed:%s", strerror(errno));
-    else if (n != size)
-        panic("write() failed");
-}
-
-void
-TCPServer::Channel::updateAddress(const AddressType &new_address)
-{
-    // check if the known address has changed (e.g. the client reconfigured
-    // its Ethernet NIC)
-    if (MultiHeaderPkt::isAddressEqual(address, new_address))
-        return;
-
-    MultiHeaderPkt::copyAddress(newAddress.first, new_address);
-    newAddress.second = true;
-}
-
-void
-TCPServer::Channel::updateAddressMap()
-{
-    assert(newAddress.second);
-    // So we have to update the address. Note that we always
-    // store the same address as key in the map but the ordering
-    // may change so we need to erase and re-insert it again.
-    auto m = TCPServer::instance->addressMap.find(&address);
-    if (m != TCPServer::instance->addressMap.end()) {
-        TCPServer::instance->addressMap.erase(m);
-    }
-    MultiHeaderPkt::copyAddress(address, newAddress.first);
-    TCPServer::instance->addressMap[&address] = this;
-    newAddress.second = false;
-}
-
-void
-TCPServer::Channel::headerPktIn()
-{
-    ssize_t n;
-    Header hdr_pkt;
-
-    assert (connected);
-
-    n = recvRaw(&hdr_pkt, sizeof(hdr_pkt));
-
-    if (n == 0) {
-        // EOF - nothing to do here, we will handle this as a POLLRDHUP event
-        // in the main loop.
-        return;
-    }
-
-    if (hdr_pkt.msgType == MsgType::dataDescriptor) {
-        updateAddress(hdr_pkt.srcAddress);
-        TCPServer::instance->xferData(hdr_pkt, *this);
-    } else {
-        processCmd(hdr_pkt);
-    }
-}
-
-void
-TCPServer::Channel::processCmd(Header &hdr_pkt)
-{
-    switch (hdr_pkt.msgType) {
-      case MsgType::cmdSyncReq:
-        assert(isSync == false);
-        isSync = true;
-        TCPServer::instance->syncProgress(
-            hdr_pkt.sendTick,
-            hdr_pkt.syncRepeat,
-            hdr_pkt.sameTick,
-            rank);
-        break;
-      case MsgType::cmdExitReq:
-        DPRINTF(debugSync, "EXIT request (rank %d tick %lu)\n",
-                rank, hdr_pkt.sendTick);
-        if (needExit)
-            inform("Multiple exit request (rank %d tick %lu)\n",
-                   rank, hdr_pkt.sendTick);
-        else
-            TCPServer::instance->numExitReq++;
-        needExit = true;
-        break;
-      case MsgType::cmdCkptReq:
-        DPRINTF(debugSync, "CKPT request (rank %d tick %lu)\n",
-                rank, hdr_pkt.sendTick);
-        if (needCkpt)
-            inform("Multiple ckpt request (rank:%d tick:%lu\n",
-                   rank, hdr_pkt.sendTick);
-        else
-            TCPServer::instance->numCkptReq++;
-        needCkpt = true;
-        break;
-      default:
-        panic("Unexpected header packet (rank:%d)",rank);
-        break;
-    }
-}
-
-TCPServer::TCPServer(unsigned clients_num,
-                     unsigned listen_port,
-                     int timeout_in_sec) :
-    nextSyncRepeat(std::numeric_limits<Tick>::max()),
-    maxSyncReqTick(0),
-    isSameTickSync(false),
-    numSyncReq(0),
-    numCkptReq(0),
-    numExitReq(0),
-    numConnectedClients(0)
-{
-    assert(instance == nullptr);
-    construct(clients_num, listen_port, timeout_in_sec);
-    instance = this;
-}
-
-TCPServer::~TCPServer()
-{
-    for (auto &c : clientsPollFd)
-        close(c.fd);
-}
-
-void
-TCPServer::construct(unsigned clients_num, unsigned port, int timeout_in_sec)
-{
-    int listen_sock, new_sock, ret;
-    unsigned client_len;
-    struct sockaddr_in server_addr, client_addr;
-    struct pollfd new_pollfd;
-    Channel new_channel;
-
-    DPRINTF(debugSetup, "Start listening on port %u ...\n", port);
-
-    listen_sock = socket(AF_INET, SOCK_STREAM, 0);
-    if (listen_sock < 0)
-        panic("socket() failed:%s", strerror(errno));
-
-    bzero(&server_addr, sizeof(server_addr));
-    server_addr.sin_family = AF_INET;
-    server_addr.sin_addr.s_addr = INADDR_ANY;
-    server_addr.sin_port = htons(port);
-    if (bind(listen_sock, (struct sockaddr *) &server_addr,
-             sizeof(server_addr)) < 0)
-        panic("bind() failed:%s", strerror(errno));
-    listen(listen_sock, 10);
-
-    clientsPollFd.reserve(clients_num);
-    clientsChannel.reserve(clients_num);
-
-    new_pollfd.events = POLLIN | POLLRDHUP;
-    new_pollfd.revents = 0;
-    while (clientsPollFd.size() < clients_num) {
-        new_pollfd.fd = listen_sock;
-        ret = poll(&new_pollfd, 1, timeout_in_sec*1000);
-        if (ret == 0)
-            panic("Timeout while waiting for clients to connect");
-        assert(ret == 1 && new_pollfd.revents == POLLIN);
-        client_len = sizeof(client_addr);
-        new_sock = accept(listen_sock,
-                          (struct sockaddr *) &client_addr,
-                          &client_len);
-        if (new_sock < 0)
-            panic("accept() failed:%s", strerror(errno));
-        new_pollfd.fd = new_sock;
-        new_pollfd.revents = 0;
-        clientsPollFd.push_back(new_pollfd);
-        new_channel.fd = new_sock;
-        new_channel.connected = true;
-        // Get rank from the client
-        new_channel.recvRaw(&new_channel.rank, sizeof(new_channel.rank));
-        // Get initial network address
-        new_channel.recvRaw(&new_channel.newAddress.first,
-                            sizeof(new_channel.newAddress.first));
-        new_channel.newAddress.second =
-            !MultiHeaderPkt::isAddressEqual(new_channel.address,
-                                            new_channel.newAddress.first);
-
-        clientsChannel.push_back(new_channel);
-
-        DPRINTF(debugSetup, "New client connection addr:%u port:%hu rank:%d\n",
-                client_addr.sin_addr.s_addr, client_addr.sin_port,
-                new_channel.rank);
-    }
-    ret = close(listen_sock);
-    assert(ret == 0);
-
-    DPRINTF(debugSetup, "Setup complete\n");
-}
-
-void
-TCPServer::run()
-{
-    int nfd;
-    numConnectedClients = clientsPollFd.size();
-
-    DPRINTF(debugSetup, "Entering run() loop\n");
-    while (numConnectedClients > 0) {
-        nfd = poll(&clientsPollFd[0], clientsPollFd.size(), -1);
-        if (nfd == -1)
-            panic("poll() failed:%s", strerror(errno));
-
-        for (unsigned i = 0, n = 0;
-             i < clientsPollFd.size() && (signed)n < nfd && numConnectedClients;
-             i++) {
-            struct pollfd &pfd = clientsPollFd[i];
-            if (pfd.revents) {
-                if (pfd.revents & POLLERR)
-                    panic("poll() returned POLLERR");
-                if (pfd.revents & POLLIN) {
-                    clientsChannel[i].headerPktIn();
-                }
-                if (pfd.revents & POLLRDHUP) {
-                    // One gem5 process exited or aborted.
-                    pfd.events = 0;
-                    if (!processExitEvent(clientsChannel[i])) {
-                        numConnectedClients = 0;
-                        break;
-                    } else {
-                        numConnectedClients--;
-                    }
-                }
-                n++;
-            }
-        }
-    }
-    DPRINTF(debugSetup, "Exiting run() loop\n");
-}
-
-bool
-TCPServer::processExitEvent(Channel &ch)
-{
-
-    DPRINTF(debugSetup, "POLLRDHUP event (rank:%d, needExit:%d)\n",
-            ch.rank, (int)ch.needExit);
-    assert (ch.connected);
-
-    // Sanity check
-    for (auto &c : clientsChannel) {
-        if ((ch.needExit != c.needExit) || c.isSync || c.needCkpt)
-            panic("Client %d closed connection unexpectedly whilst client %d"
-                  "is active (needExit %d isSync %d needCkpt %d)",
-                  ch.rank, c.rank, c.needExit, c.isSync, c.needCkpt);
-    }
-    ch.connected = false;
-    return ch.needExit;
-}
-
-void
-TCPServer::xferData(const Header &hdr_pkt, const Channel &src)
-{
-    unsigned n;
-    assert(hdr_pkt.dataPacketLength <= sizeof(packetBuffer));
-    n = src.recvRaw(packetBuffer, hdr_pkt.dataPacketLength);
-
-    if (n == 0)
-        panic("recvRaw() failed");
-    DPRINTF(debugPkt, "Incoming data packet (from rank %d) "
-            "src:0x%02x%02x%02x%02x%02x%02x "
-            "dst:0x%02x%02x%02x%02x%02x%02x\n",
-            src.rank,
-            hdr_pkt.srcAddress[0],
-            hdr_pkt.srcAddress[1],
-            hdr_pkt.srcAddress[2],
-            hdr_pkt.srcAddress[3],
-            hdr_pkt.srcAddress[4],
-            hdr_pkt.srcAddress[5],
-            hdr_pkt.dstAddress[0],
-            hdr_pkt.dstAddress[1],
-            hdr_pkt.dstAddress[2],
-            hdr_pkt.dstAddress[3],
-            hdr_pkt.dstAddress[4],
-            hdr_pkt.dstAddress[5]);
-    // Now try to figure out the destination client(s).
-    auto dst_info = addressMap.find(&hdr_pkt.dstAddress);
-
-    // First handle the multicast/broadcast or unknonw destination case. These
-    // all trigger a broadcast of the packet to all clients.
-    if (MultiHeaderPkt::isUnicastAddress(hdr_pkt.dstAddress) == false ||
-        dst_info == addressMap.end()) {
-        unsigned n = 0;
-        for (auto const &c: clientsChannel) {
-            if (c.connected && (&c != &src)) {
-                c.sendRaw(&hdr_pkt, sizeof(hdr_pkt));
-                c.sendRaw(packetBuffer, hdr_pkt.dataPacketLength);
-                n++;
-            }
-        }
-        if (n == 0) {
-            inform("Broadcast/multicast packet dropped\n");
-        }
-    } else {
-        // It is a unicast address with a known destination
-        Channel *dst = dst_info->second;
-        if ( dst->connected) {
-            dst->sendRaw(&hdr_pkt, sizeof(hdr_pkt));
-            dst->sendRaw(packetBuffer, hdr_pkt.dataPacketLength);
-            DPRINTF(debugPkt, "Unicast packet sent (from/to rank %d/%d)\n",
-                    src.rank, dst->rank);
-        } else {
-            inform("Unicast packet dropped - destination exited "
-                   "(from/to rank %d/%d\n", src.rank, dst->rank);
-        }
-    }
-}
-
-void
-TCPServer::syncProgress(Tick send_tick, Tick next_sync_repeat,
-                        bool same_tick, unsigned rank)
-{
-    DPRINTF(same_tick ? debugPeriodic : debugSync,
-            "Sync request rank:%d tick:%lu\n", rank, send_tick);
-
-    assert(numSyncReq == 0 || (same_tick == isSameTickSync));
-    assert(!same_tick || (numSyncReq == 0) ||
-           (isSameTickSync && (maxSyncReqTick == send_tick)));
-    isSameTickSync = same_tick;
-    if (maxSyncReqTick < send_tick)
-        maxSyncReqTick = send_tick;
-
-    if (next_sync_repeat < nextSyncRepeat) {
-        nextSyncRepeat = next_sync_repeat;
-        inform("Periodic sync repeat is adjusted to %lu\n", nextSyncRepeat);
-    }
-    assert(numSyncReq < numConnectedClients);
-    numSyncReq++;
-    if (numSyncReq < numConnectedClients)
-        return;
-
-    // Sync complete, send out the acks
-    MultiHeaderPkt::Header hdr_pkt;
-    hdr_pkt.msgType = MsgType::cmdSyncAck;
-    hdr_pkt.maxSyncReqTick = maxSyncReqTick;
-    hdr_pkt.syncRepeat = nextSyncRepeat;
-    assert(numCkptReq <= numConnectedClients);
-
-    bool coll_ckpt = (numCkptReq == numConnectedClients);
-    if (coll_ckpt) {
-        hdr_pkt.doCkpt = true;
-        numCkptReq = 0;
-    } else {
-        hdr_pkt.doCkpt = false;
-    }
-
-    assert(numExitReq <= numConnectedClients);
-    if (numExitReq == numConnectedClients) {
-        hdr_pkt.doExit =  true;
-        numExitReq = 0;
-    } else {
-        hdr_pkt.doExit = false;
-    }
-
-    for (auto &c : clientsChannel) {
-        if (c.connected) {
-            c.sendRaw(&hdr_pkt, sizeof(hdr_pkt));
-            c.isSync = false;
-            if (coll_ckpt)
-                c.needCkpt = false;
-            // Update the address map at each peridoc sync if the channel has
-            // new address
-            if (c.newAddress.second == true && isSameTickSync)
-                c.updateAddressMap();
-        }
-    }
-    DPRINTF(isSameTickSync ? debugPeriodic : debugSync, "Sync COMPLETE\n");
-    numSyncReq = 0;
-    maxSyncReqTick = 0;
-    isSameTickSync = false;
-}
-
-void
-sigtermHandler(int sig)
-{
-    if (TCPServer::getInstance() != nullptr)
-        delete TCPServer::getInstance();
-    panic("Got SIGTERM\n");
-}
-
-int
-main(int argc, char *argv[])
-{
-    TCPServer *server = nullptr;
-    int clients_num = -1, listen_port = -1;
-    int first_arg = 1, timeout_in_sec = 60;
-
-    if (argc > 1 && string(argv[1]).compare("-debug") == 0) {
-        timeout_in_sec = -1;
-        first_arg++;
-        argc--;
-    }
-
-    if (argc != 3)
-        panic("We need two command line args (number of clients and tcp listen"
-              " port");
-
-    signal(SIGTERM, sigtermHandler);
-
-    clients_num = atoi(argv[first_arg]);
-    listen_port = atoi(argv[first_arg + 1]);
-
-    server = new TCPServer(clients_num, listen_port, timeout_in_sec);
-
-    server->run();
-
-    delete server;
-
-    return 0;
-}
diff --git a/util/multi/tcp_server.hh b/util/multi/tcp_server.hh
deleted file mode 100644
--- a/util/multi/tcp_server.hh
+++ /dev/null
@@ -1,282 +0,0 @@
-/*
- * Copyright (c) 2015 ARM Limited
- * All rights reserved
- *
- * The license below extends only to copyright in the software and shall
- * not be construed as granting a license to any other intellectual
- * property including but not limited to intellectual property relating
- * to a hardware implementation of the functionality of the software
- * licensed hereunder.  You may use the software subject to the license
- * terms below provided that you ensure that this notice is replicated
- * unmodified and in its entirety in all distributions of the software,
- * modified or unmodified, in source code or in binary form.
- *
- * Copyright (c) 2008 The Regents of The University of Michigan
- * All rights reserved.
- *
- * Redistribution and use in source and binary forms, with or without
- * modification, are permitted provided that the following conditions are
- * met: redistributions of source code must retain the above copyright
- * notice, this list of conditions and the following disclaimer;
- * redistributions in binary form must reproduce the above copyright
- * notice, this list of conditions and the following disclaimer in the
- * documentation and/or other materials provided with the distribution;
- * neither the name of the copyright holders nor the names of its
- * contributors may be used to endorse or promote products derived from
- * this software without specific prior written permission.
- *
- * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
- * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
- * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
- * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
- * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
- * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
- * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
- * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
- * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
- * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
- * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
- *
- * Authors: Gabor Dozsa
- */
-
-/* @file
- *  Message server using TCP stream sockets for parallel gem5 runs.
- *
- * For a high level description about multi gem5 see comments in
- * header files src/dev/multi_iface.hh and src/dev/tcp_iface.hh.
- *
- * This file implements the central message server process for multi gem5.
- * The server is responsible the following tasks.
- * 1. Establishing a TCP socket connection for each gem5 process (clients).
- *
- * 2. Process data messages coming in from clients. The server checks
- * the MAC addresses in the header message and transfers the message
- * to the target(s) client(s).
- *
- * 3. Processing synchronisation related control messages. Synchronisation
- * is performed as follows. The server waits for a 'barrier enter' message
- * from all the clients. When the last such control message arrives, the
- * server sends out a 'barrier leave' control message to all the clients.
- *
- * 4. Triggers complete termination in case a client exits. A client may
- * exit either by calling 'm5 exit' pseudo instruction or due to a fatal
- * error. In either case, we assume that the entire multi simulation needs to
- * terminate. The server triggers full termination by tearing down the
- * open TCP sockets.
- *
- * The TCPServer class is instantiated as a singleton object.
- *
- * The server can be built independently from the rest of gem5 (and it is
- * architecture agnostic). See the Makefile in the same directory.
- *
- */
-
-#include <poll.h>
-
-#include <map>
-#include <vector>
-
-#include "dev/multi_packet.hh"
-
-/**
- * The maximum length of an Ethernet packet (allowing Jumbo frames).
- */
-#define MAX_ETH_PACKET_LENGTH 9014
-
-class TCPServer
-{
-  public:
-    typedef MultiHeaderPkt::AddressType AddressType;
-    typedef MultiHeaderPkt::Header Header;
-    typedef MultiHeaderPkt::MsgType MsgType;
-
-  private:
-    /**
-     * The Channel class encapsulates all the information about a client
-     * and its current status.
-     */
-    class Channel
-    {
-      private:
-        /**
-         * Update the client MAC address. It is called every time a new data
-         * packet is to come in.
-         */
-        void updateAddress(const AddressType &new_addr);
-        /**
-         * Process an incoming command message.
-         */
-        void processCmd(Header &hdr_packet);
-
-      public:
-        /**
-         * TCP stream socket.
-         */
-        int fd;
-        /**
-         * Flag for on-going sync
-         */
-        bool isSync;
-        /**
-         *  Multi rank of the client
-         */
-        unsigned rank;
-        /**
-         * Flag to is true if client is connected
-         */
-        bool connected;
-        /**
-         * Flag to is true if client has requested exit
-         */
-        bool needExit;
-        /**
-         * Flag to is true if client has requested checkppint
-         */
-        bool needCkpt;
-        /**
-         * Current network address of the client
-         */
-        AddressType address;
-        /**
-         * New network address of the client.
-         *
-         * @note For the sake of deterministic runs, we do not use an updated
-         * address until the next periodic sync completes. That avoids race
-         * conditions regarding broadcast/unicast data packets.
-         */
-        typedef std::pair<AddressType,bool> AddressInfo;
-        AddressInfo newAddress;
-
-      public:
-        Channel();
-        ~Channel () {}
-        /**
-         * Receive and process the next incoming header packet.
-         */
-        void headerPktIn();
-        /**
-         * Send raw data to the connected client.
-         *
-         * @param data The data to send.
-         * @param size Size of the data (in bytes).
-         */
-        void sendRaw(const void *data, unsigned size) const;
-        /**
-         * Register an address change in the address map.
-         *
-         * @note This method is only called when a periodic sync completes
-         */
-        void updateAddressMap();
-        /**
-         * Receive raw data from the connected client.
-         *
-         * @param buf The buffer to store the incoming data into.
-         * @param size Size of data to receive (in bytes).
-         * @return In case of success, it returns size. Zero is returned
-         * if the socket is already closed by the client.
-         */
-        unsigned recvRaw(void *buf, unsigned size) const;
-    };
-    /**
-     * The array of socket descriptors needed by the poll() system call.
-     */
-    std::vector<struct pollfd> clientsPollFd;
-    /**
-     * Array holding all clients info.
-     */
-    std::vector<Channel> clientsChannel;
-    /**
-     * We use a map to select the target client based on the destination
-     * MAC address.
-     */
-    struct AddressCompare
-    {
-        bool operator()(const AddressType *a1, const AddressType *a2)
-        {
-            return MultiHeaderPkt::isAddressLess(*a1, *a2);
-        }
-    };
-    std::map<const AddressType *, Channel *, AddressCompare> addressMap;
-    /**
-     * As we dealt with only one message at a time, we can allocate and re-use
-     * a single packet buffer (to hold any incoming data packet).
-     */
-    uint8_t packetBuffer[MAX_ETH_PACKET_LENGTH];
-    /**
-     * The repeat value for the next periodic sync
-     */
-    Tick nextSyncRepeat;
-    /**
-     * Max send tick of the current sync.
-     */
-    Tick maxSyncReqTick;
-    /*
-     * Is the current sync must happen at the same tick in clients?
-     */
-    bool isSameTickSync;
-    /*
-     * Number of current sync requets.
-     */
-    unsigned numSyncReq;
-    /*
-     * Number of current ckpt requests.
-     */
-    unsigned numCkptReq;
-    /*
-     * Number of current exit requests.
-     */
-    unsigned numExitReq;
-    /*
-     * Number of connected clients.
-     */
-    unsigned numConnectedClients;
-    /**
-     * The singleton server object.
-     */
-    static TCPServer *instance;
-    /**
-     * Set up the socket connections to all the clients.
-     *
-     * @param listen_port The port we are listening on for new client
-     * connection requests.
-     * @param nclients The number of clients to connect to.
-     * @param timeout Timeout in sec to complete the setup phase (i.e. all gem5
-     * establish socket connections)
-     */
-    void construct(unsigned listen_port, unsigned nclients, int timeout);
-    /**
-     * Transfer the header and the follow up data packet to the target(s)
-     * clients.
-     *
-     * @param hdr The header message structure.
-     * @param ch The source channel for the message.
-     */
-    void xferData(const Header &hdr, const Channel &ch);
-    /**
-     * Process a new sync request.
-     */
-    void syncProgress(Tick send_tick, Tick sync_repeat, bool is_periodic, unsigned rank);
-    /**
-     * Process a client exit event
-     *
-     * @param ch The channel on which the client exit event occured.
-     *
-     * @return False if this event must trigger a global exit.
-     */
-    bool processExitEvent(Channel &ch);
-
-  public:
-
-    TCPServer(unsigned clients_num, unsigned listen_port, int timeout_in_sec);
-    ~TCPServer();
-
-    /**
-     * The main server loop that waits for and processes incoming messages.
-     */
-    void run();
-    /**
-     * The singleton server object.
-     */
-  static TCPServer *getInstance() { return instance; }
-};
diff --git a/util/multi/test/bootscript.rcS b/util/multi/test/bootscript.rcS
deleted file mode 100644
--- a/util/multi/test/bootscript.rcS
+++ /dev/null
@@ -1,149 +0,0 @@
-#!/bin/bash
-
-
-#
-# Copyright (c) 2015 ARM Limited
-# All rights reserved
-#
-# The license below extends only to copyright in the software and shall
-# not be construed as granting a license to any other intellectual
-# property including but not limited to intellectual property relating
-# to a hardware implementation of the functionality of the software
-# licensed hereunder.  You may use the software subject to the license
-# terms below provided that you ensure that this notice is replicated
-# unmodified and in its entirety in all distributions of the software,
-# modified or unmodified, in source code or in binary form.
-#
-# Redistribution and use in source and binary forms, with or without
-# modification, are permitted provided that the following conditions are
-# met: redistributions of source code must retain the above copyright
-# notice, this list of conditions and the following disclaimer;
-# redistributions in binary form must reproduce the above copyright
-# notice, this list of conditions and the following disclaimer in the
-# documentation and/or other materials provided with the distribution;
-# neither the name of the copyright holders nor the names of its
-# contributors may be used to endorse or promote products derived from
-# this software without specific prior written permission.
-#
-# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
-# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
-# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
-# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
-# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
-# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
-# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-#
-# Authors: Gabor Dozsa
-#
-#
-# This is an example boot script to use for multi gem5 runs. The important
-# task here is to extract the rank and size information through the m5
-# initparam utility and use those to configure MAC/IP addresses and hostname.
-#
-# You are expected to customize this scipt for your needs (e.g. change
-# the command at the end of the scipt to run your tests/workloads.
-
-source /root/.bashrc
-echo "bootscript.rcS is running"
-
-# Retrieve multi-gem5 rank and size parameters using magic keys
-MY_RANK=$(/sbin/m5 initparam 1234)
-[ $? = 0 ] || { echo "m5 initparam failed"; exit -1; }
-MY_SIZE=$(/sbin/m5 initparam 1235)
-[ $? = 0 ] || { echo "m5 initparam failed"; exit -1; }
-
-
-echo "***** Start boot script! *****"
-if [ "${RUNSCRIPT_VAR+set}" != set ]
-then
-    # Signal our future self that it's safe to continue
-    echo "RUNSCRIPT_VAR not set! Setting it ..."
-    export RUNSCRIPT_VAR=1
-else
-    if [ "$MY_RANK" == "0" ]
-    then
-        # We've already executed once, so we should exit
-        echo "calling m5 exit!"
-        /sbin/m5 exit
-    else
-        echo "Else part - RUNSCRIPT_VAR1_TUX1 is set! So reload and execute!"
-        echo "Else part - Loading new script..."
-        /sbin/m5 readfile > /tmp/runscript1.sh
-        chmod 755 /tmp/runscript1.sh
-
-        # Execute the new runscript
-        if [ -s /tmp/runscript1.sh ]
-        then
-            #/system/bin/sh /data/runscript1.sh
-            echo "Else part - executing newly loaded script ...!"
-            /bin/bash /tmp/runscript1.sh
-        else 
-            echo "Else part - Script not specified."
-            echo "Else part - Exiting..." 
-            /sbin/m5 exit
-        fi
-    fi
-fi
-
-/bin/hostname node${MY_RANK}
-
-# Keep MAC address assignment simple for now ...
-(($MY_RANK > 97)) && { echo "(E) Rank must be less than 98"; /sbin/m5 abort; }
-((MY_ADDR = MY_RANK + 2))
-if (($MY_ADDR < 10))
-then
-    MY_ADDR_PADDED=0${MY_ADDR}
-else
-    MY_ADDR_PADDED=${MY_ADDR}
-fi
-
-/sbin/ifconfig eth0 hw ether 00:90:00:00:00:${MY_ADDR_PADDED}
-/sbin/ifconfig eth0 192.168.0.${MY_ADDR} netmask 255.255.255.0 up
-
-/sbin/ifconfig -a
-
-echo "Hello from $MY_RANK of $MY_SIZE"
-
-
-if [ "$MY_RANK" == "0" ]
-then
-    # Trigger an immediate checkpoint at the next sync (by passing a non-zero
-    # delay param to m5 ckpt)
-    /sbin/m5 checkpoint 1
-else
-    # do nothing, just iterate through the script
-    echo "do nothing, just iterate through the script ..."
-fi
-
-#THIS IS WHERE EXECUTION BEGINS FROM AFTER RESTORING FROM CKPT
-if [ "$RUNSCRIPT_VAR" -eq 1 ]
-then
-
-    # Signal our future self not to recurse infinitely
-    export RUNSCRIPT_VAR=2
-    echo "3. RUNSCRIPT_VAR is $RUNSCRIPT_VAR"
-
-    # Read the script for the checkpoint restored execution
-    echo "Loading new script..."
-    /sbin/m5 readfile > /tmp/runscript1.sh
-    chmod 755 /tmp/runscript1.sh
-
-    # Execute the new runscript
-    if [ -s /tmp/runscript1.sh ]
-    then
-        #/system/bin/sh /data/runscript1.sh
-        echo "executing newly loaded script ..."
-        /bin/bash /tmp/runscript1.sh
-
-    else
-        echo "Script not specified. Dropping into shell..."
-    fi
-
-fi
-
-echo "Fell through script. Exiting..."
-/sbin/m5 exit
diff --git a/util/multi/test/test-2nodes-AArch64.sh b/util/multi/test/test-2nodes-AArch64.sh
deleted file mode 100755
--- a/util/multi/test/test-2nodes-AArch64.sh
+++ /dev/null
@@ -1,79 +0,0 @@
-#! /bin/bash
-
-#
-# Copyright (c) 2015 ARM Limited
-# All rights reserved
-#
-# The license below extends only to copyright in the software and shall
-# not be construed as granting a license to any other intellectual
-# property including but not limited to intellectual property relating
-# to a hardware implementation of the functionality of the software
-# licensed hereunder.  You may use the software subject to the license
-# terms below provided that you ensure that this notice is replicated
-# unmodified and in its entirety in all distributions of the software,
-# modified or unmodified, in source code or in binary form.
-#
-# Redistribution and use in source and binary forms, with or without
-# modification, are permitted provided that the following conditions are
-# met: redistributions of source code must retain the above copyright
-# notice, this list of conditions and the following disclaimer;
-# redistributions in binary form must reproduce the above copyright
-# notice, this list of conditions and the following disclaimer in the
-# documentation and/or other materials provided with the distribution;
-# neither the name of the copyright holders nor the names of its
-# contributors may be used to endorse or promote products derived from
-# this software without specific prior written permission.
-#
-# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
-# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
-# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
-# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
-# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
-# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
-# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-#
-# Authors: Gabor Dozsa
-#
-#
-# This is an example script to start a multi gem5 simulations using
-# two AArch64 systems. It is also uses the example
-# multi gem5 bootscript util/multi/test/bootscript.rcS that will run the
-# linux ping command to check if we can see the peer system connected via
-# the simulated Ethernet link.
-
-GEM5_DIR=$(pwd)/$(dirname $0)/../../..
-
-#M5_PATH=$HOME/GEM5/public_dist
-#export M5_PATH
-
-
-
-IMG=$M5_PATH/disks/aarch64-ubuntu-trusty-headless.img
-VMLINUX=$M5_PATH/binaries/vmlinux.aarch64.20140821
-DTB=$M5_PATH/binaries/vexpress.aarch64.20140821.dtb
-
-SYS_CONFIG=$GEM5_DIR/configs/example/fs.py
-#SYS_CONFIG=$HOME/GEM5/BRANDNEW/gem5-obj/configs/hpc/RealViewHPC.py
-GEM5_EXE=$GEM5_DIR/build/ARM/gem5.opt
-
-BOOT_SCRIPT=$GEM5_DIR/util/multi/test/bootscript.rcS
-GEM5_MULTI_SH=$GEM5_DIR/util/multi/gem5-multi.sh
-
-DEBUG_FLAGS="-d MultiEthernet,MultiEthernetPkt"
-#CHKPT_RESTORE="-r1"
-
-NNODES=2
-
-$GEM5_MULTI_SH $DEBUG_FLAGS -n $NNODES -f $SYS_CONFIG $GEM5_EXE   \
-    --cpu-type=atomic                                          \
-    --num-cpus=1                                               \
-    --machine-type=VExpress_EMM64                              \
-    --disk-image=$IMG                                          \
-    --kernel=$VMLINUX                                          \
-    --dtb-filename=$DTB                                        \
-    --script=$BOOT_SCRIPT                                      \
-    $CHKPT_RESTORE
