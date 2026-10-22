        | cpu-probe - the CPU probe (AE 0011) for the Analog Rytm MKII, OS 1.74.
        |
        | Three live readouts of the processor's load, shown as the labels of
        | SETTINGS > MIDI CONFIG > CHANNELS (the settings themselves are untouched):
        |
        |   PERF CHANNEL   ->  CPU 78.3%     time not spent idle, all of it
        |   AUTO CHANNEL   ->  AUDIO 61.2%   the audio interrupt's average share
        |   PROG CH IN CH  ->  PEAK 74.0%    its largest share of one block
        |
        | Each readout covers the time since it last drew (the menu redraws them
        | as it repaints), so leave the page up for a few seconds while playing.
        |
        | Timer: DMA timer 0's counter, free-running at the 132 MHz bus clock
        | (core-ar2 starts it at boot if nothing has; the OS reads it as its time
        | base too).
        |
        | Audio: DTCN0 at core's ev_render_in and ev_render_out, the audio
        | interrupt's entry (0x4011fb6e, after its prologue) and its one exit
        | (0x401216c2, before its epilogue): run time over the interval between
        | entries, summed over the window for the average, the largest single
        | block for the peak. Intervals that are stalls, not blocks, are left out.
        | The MK1 build timed the interrupt from its own detours; here core owns
        | those places, so the prologue, the epilogue and core's dispatch of the
        | other mods' handlers ordered before (in) or after (out) this one are
        | not counted.
        |
        | CPU: main() ends in `bra.s .` (0x40100a7e) once it has started the OS'
        | tasks: the code that runs when no task or interrupt wants the processor.
        | Its last call (jsr 0x400a34d4 at 0x40100a8c, the task that it creates
        | and starts) is repointed here, makes that call, then never returns: it
        | reads DTCN0 in a loop and adds up the gaps between reads that are short
        | enough to be its own loop (under GAP_MAX ticks). Any gap an interrupt or
        | a task took is longer and not counted. CPU = 1 - idle time / elapsed.

        .equ    DTCN0,          0xfc07000c
        .equ    MAIN_LAST,      0x400a34d4        | main()'s last call before its spin
        .equ    LBL_PERF_R,     0x400459dc        | the three label getters, past
        .equ    LBL_AUTO_R,     0x40045a04        | their `pea "LABEL"`
        .equ    LBL_PROG_R,     0x40045a2c
        .equ    GAP_MAX,        132               | ticks: 1 us at the 132 MHz bus
        .equ    STALL,          0x00400000        | an interval this long is not a block

        .equ    V_T0,           0                 | the audio interrupt's last entry
        .equ    V_IV,           4                 | the interval before it
        .equ    V_ASUM,         8                 | run time, this window
        .equ    V_AIV,          12                | intervals, this window
        .equ    V_PEAK,         16                | largest block, 0.1 %
        .equ    V_IDLE,         20                | idle ticks, this window
        .equ    V_CT0,          24                | the CPU window's start
        .equ    V_BUF,          32                | label text, 16 B each

        .bss
        .align  4
pv:     .space  V_BUF+48                          | core clears .bss at boot

        .text

        | ------------------------------------------------------------------
        | ev_render_in: the audio interrupt's entry. d0/d1/a0/a1 are free.
        | ------------------------------------------------------------------
        .globl  cpu_probe_in
        .align  2
cpu_probe_in:
        lea     pv,%a0
        move.l  DTCN0,%d0
        move.l  V_T0(%a0),%d1
        move.l  %d0,V_T0(%a0)
        sub.l   %d1,%d0
        move.l  %d0,V_IV(%a0)
        rts

        | ------------------------------------------------------------------
        | ev_render_out: its exit. d0/d1/a0/a1 are free; d2 is kept. Nothing
        | here uses the MAC.
        | ------------------------------------------------------------------
        .globl  cpu_probe_out
        .align  2
cpu_probe_out:
        move.l  %d2,-(%sp)
        lea     pv,%a0
        move.l  DTCN0,%d0
        sub.l   V_T0(%a0),%d0                     | run
        move.l  V_IV(%a0),%d1
        beq.s   9f
        cmp.l   %d1,%d0
        bhi.s   9f
        cmp.l   #STALL,%d1
        bcc.s   9f
        move.l  V_AIV(%a0),%d2                    | keep the sums in range: halve
        cmp.l   #0x40000000,%d2                   | both if nobody reads them
        bcs.s   1f
        lsr.l   #1,%d2
        move.l  %d2,V_AIV(%a0)
        move.l  V_ASUM(%a0),%d2
        lsr.l   #1,%d2
        move.l  %d2,V_ASUM(%a0)
1:      add.l   %d0,V_ASUM(%a0)
        add.l   %d1,V_AIV(%a0)
        move.l  #1000,%d2
        mulu.l  %d2,%d0
        divu.l  %d1,%d0                           | this block, 0.1 %
        cmp.l   V_PEAK(%a0),%d0
        bls.s   9f
        move.l  %d0,V_PEAK(%a0)
9:      move.l  (%sp)+,%d2
        rts

        | ------------------------------------------------------------------
        | main()'s last call, then the idle loop in place of its `bra.s .`.
        | ------------------------------------------------------------------
        .globl  cpu_probe_idle
        .align  2
cpu_probe_idle:
        jsr     MAIN_LAST
        lea     pv,%a0
        move.l  DTCN0,%d1
        move.l  %d1,V_CT0(%a0)
        clr.l   V_IDLE(%a0)
2:      move.l  DTCN0,%d0
        move.l  %d0,%d2
        sub.l   %d1,%d2
        move.l  %d0,%d1
        cmp.l   #GAP_MAX,%d2
        bcc.s   2b                                | interrupted: not idle time
        add.l   %d2,V_IDLE(%a0)
        bra.s   2b

        | ------------------------------------------------------------------
        | The three label getters, each at its `pea "LABEL"`: a0 holds the string
        | being built and must survive; d0/d1/a1 are free, and d2 is about to be
        | loaded from a0. Push the text instead and rejoin.
        | ------------------------------------------------------------------
        .globl  cpu_probe_perf
        .align  2
cpu_probe_perf:
        move.l  %a0,-(%sp)
        lea     pv,%a0
        move.l  DTCN0,%d0
        move.l  V_CT0(%a0),%d1
        move.l  %d0,V_CT0(%a0)
        sub.l   %d1,%d0                           | elapsed
        move.l  V_IDLE(%a0),%d1
        clr.l   V_IDLE(%a0)
        jsr     tenths                            | idle, 0.1 %
        neg.l   %d0
        add.l   #1000,%d0                         | busy
        lea     str_cpu,%a1
        moveq   #0,%d1
        jsr     label
        move.l  (%sp)+,%a0
        pea     pv+V_BUF
        jmp     LBL_PERF_R

        .globl  cpu_probe_auto
        .align  2
cpu_probe_auto:
        move.l  %a0,-(%sp)
        lea     pv,%a0
        move.l  V_AIV(%a0),%d0
        move.l  V_ASUM(%a0),%d1
        clr.l   V_AIV(%a0)
        clr.l   V_ASUM(%a0)
        jsr     tenths
        lea     str_audio,%a1
        moveq   #16,%d1
        jsr     label
        move.l  (%sp)+,%a0
        pea     pv+V_BUF+16
        jmp     LBL_AUTO_R

        .globl  cpu_probe_prog
        .align  2
cpu_probe_prog:
        move.l  %a0,-(%sp)
        lea     pv,%a0
        move.l  V_PEAK(%a0),%d0
        clr.l   V_PEAK(%a0)
        lea     str_peak,%a1
        moveq   #32,%d1
        jsr     label
        move.l  (%sp)+,%a0
        pea     pv+V_BUF+32
        jmp     LBL_PROG_R

        | tenths(d1 = part, d0 = whole) -> d0 = part / whole in 0.1 %, 0..1000.
        | Clobbers d1.
        .align  2
tenths:
1:      cmp.l   #0x003fffff,%d0                   | so part * 1000 fits 32 bits
        bls.s   2f
        lsr.l   #1,%d0
        lsr.l   #1,%d1
        bra.s   1b
2:      tst.l   %d0
        beq.s   8f
        move.l  %d2,-(%sp)
        move.l  #1000,%d2
        mulu.l  %d2,%d1
        divu.l  %d0,%d1
        move.l  (%sp)+,%d2
        move.l  %d1,%d0
        cmp.l   #1000,%d0
        bls.s   9f
        move.l  #1000,%d0
9:      rts
8:      moveq   #0,%d0
        rts

        | label(d0 = 0.1 %, a1 = prefix, d1 = buffer offset): "PREFIX 12.3%" into
        | pv+V_BUF+d1. Clobbers d0/d1/a1, keeps a0 = pv.
        .align  2
label:
        move.l  %a2,-(%sp)
        lea     V_BUF(%a0,%d1.l),%a2
1:      move.b  (%a1)+,%d1
        move.b  %d1,(%a2)+
        bne.s   1b
        subq.l  #1,%a2
        cmp.l   #1000,%d0
        bls.s   2f
        move.l  #1000,%d0
2:      divu.w  #10,%d0                           | whole percent, tenths in the high word
        move.l  %d0,%d1
        and.l   #0xffff,%d0
        divu.w  #10,%d0                           | tens, units
        tst.w   %d0
        beq.s   4f
        cmp.w   #10,%d0                           | 100
        bne.s   3f
        move.b  #0x31,(%a2)+
        moveq   #0,%d0
3:      add.l   #0x30,%d0
        move.b  %d0,(%a2)+
4:      swap    %d0
        add.l   #0x30,%d0
        move.b  %d0,(%a2)+
        move.b  #0x2e,(%a2)+                      | .
        swap    %d1
        add.l   #0x30,%d1
        move.b  %d1,(%a2)+
        move.b  #0x25,(%a2)+                      | %
        clr.b   (%a2)
        move.l  (%sp)+,%a2
        rts

str_cpu:        .asciz  "CPU "
str_audio:      .asciz  "AUDIO "
str_peak:       .asciz  "PEAK "
        .align  2
