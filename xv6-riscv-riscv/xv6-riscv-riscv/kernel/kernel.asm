
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ce70713          	addi	a4,a4,-1842 # 80008920 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	cbc78793          	addi	a5,a5,-836 # 80005d20 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc66f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	41e080e7          	jalr	1054(ra) # 8000254a <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	8d450513          	addi	a0,a0,-1836 # 80010a60 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	8c448493          	addi	s1,s1,-1852 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	95290913          	addi	s2,s2,-1710 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	1c8080e7          	jalr	456(ra) # 80002394 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	f12080e7          	jalr	-238(ra) # 800020ec <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	2de080e7          	jalr	734(ra) # 800024f4 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	83650513          	addi	a0,a0,-1994 # 80010a60 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	82050513          	addi	a0,a0,-2016 # 80010a60 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	88f72023          	sw	a5,-1920(a4) # 80010af8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	78e50513          	addi	a0,a0,1934 # 80010a60 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	2a8080e7          	jalr	680(ra) # 800025a0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	76050513          	addi	a0,a0,1888 # 80010a60 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	73c70713          	addi	a4,a4,1852 # 80010a60 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	71278793          	addi	a5,a5,1810 # 80010a60 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	77c7a783          	lw	a5,1916(a5) # 80010af8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	6d070713          	addi	a4,a4,1744 # 80010a60 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	6c048493          	addi	s1,s1,1728 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	68470713          	addi	a4,a4,1668 # 80010a60 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	70f72723          	sw	a5,1806(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	64878793          	addi	a5,a5,1608 # 80010a60 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	6cc7a023          	sw	a2,1728(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	6b450513          	addi	a0,a0,1716 # 80010af8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	d04080e7          	jalr	-764(ra) # 80002150 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	5fa50513          	addi	a0,a0,1530 # 80010a60 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	b7a78793          	addi	a5,a5,-1158 # 80020ff8 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	5c07a823          	sw	zero,1488(a5) # 80010b20 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	34f72e23          	sw	a5,860(a4) # 800088e0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	560dad83          	lw	s11,1376(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	50a50513          	addi	a0,a0,1290 # 80010b08 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	3a650513          	addi	a0,a0,934 # 80010b08 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	38a48493          	addi	s1,s1,906 # 80010b08 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	34a50513          	addi	a0,a0,842 # 80010b28 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	0d67a783          	lw	a5,214(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	0a273703          	ld	a4,162(a4) # 800088e8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0a27b783          	ld	a5,162(a5) # 800088f0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	2b8a0a13          	addi	s4,s4,696 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	07048493          	addi	s1,s1,112 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	07098993          	addi	s3,s3,112 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	8aa080e7          	jalr	-1878(ra) # 80002150 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	24650513          	addi	a0,a0,582 # 80010b28 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fee7a783          	lw	a5,-18(a5) # 800088e0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	ff47b783          	ld	a5,-12(a5) # 800088f0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	fe473703          	ld	a4,-28(a4) # 800088e8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	218a0a13          	addi	s4,s4,536 # 80010b28 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	fd048493          	addi	s1,s1,-48 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	fd090913          	addi	s2,s2,-48 # 800088f0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	7bc080e7          	jalr	1980(ra) # 800020ec <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	1e248493          	addi	s1,s1,482 # 80010b28 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	f8f73b23          	sd	a5,-106(a4) # 800088f0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	15848493          	addi	s1,s1,344 # 80010b28 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	77e78793          	addi	a5,a5,1918 # 80022190 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	12e90913          	addi	s2,s2,302 # 80010b60 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	09250513          	addi	a0,a0,146 # 80010b60 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	6ae50513          	addi	a0,a0,1710 # 80022190 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	05c48493          	addi	s1,s1,92 # 80010b60 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	04450513          	addi	a0,a0,68 # 80010b60 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	01850513          	addi	a0,a0,24 # 80010b60 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	a5470713          	addi	a4,a4,-1452 # 800088f8 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	8a0080e7          	jalr	-1888(ra) # 8000277a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	e7e080e7          	jalr	-386(ra) # 80005d60 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fe2080e7          	jalr	-30(ra) # 80001ecc <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	800080e7          	jalr	-2048(ra) # 80002752 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	820080e7          	jalr	-2016(ra) # 8000277a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	de8080e7          	jalr	-536(ra) # 80005d4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	df6080e7          	jalr	-522(ra) # 80005d60 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	fa8080e7          	jalr	-88(ra) # 80002f1a <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	64c080e7          	jalr	1612(ra) # 800035c6 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	5ea080e7          	jalr	1514(ra) # 8000456c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	ede080e7          	jalr	-290(ra) # 80005e68 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d20080e7          	jalr	-736(ra) # 80001cb2 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	94f72c23          	sw	a5,-1704(a4) # 800088f8 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	94c7b783          	ld	a5,-1716(a5) # 80008900 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00007797          	auipc	a5,0x7
    80001274:	68a7b823          	sd	a0,1680(a5) # 80008900 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	0000f497          	auipc	s1,0xf
    8000186a:	74a48493          	addi	s1,s1,1866 # 80010fb0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001880:	00015a17          	auipc	s4,0x15
    80001884:	530a0a13          	addi	s4,s4,1328 # 80016db0 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if(pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ba:	17848493          	addi	s1,s1,376
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	27e50513          	addi	a0,a0,638 # 80010b80 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	27e50513          	addi	a0,a0,638 # 80010b98 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	0000f497          	auipc	s1,0xf
    8000192e:	68648493          	addi	s1,s1,1670 # 80010fb0 <proc>
      initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	00015997          	auipc	s3,0x15
    80001950:	46498993          	addi	s3,s3,1124 # 80016db0 <tickslock>
      initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e8bc                	sd	a5,80(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	17848493          	addi	s1,s1,376
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	1fa50513          	addi	a0,a0,506 # 80010bb0 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	1a270713          	addi	a4,a4,418 # 80010b80 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first) {
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e5a7a783          	lw	a5,-422(a5) # 80008870 <first.1688>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	d72080e7          	jalr	-654(ra) # 80002792 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e407a023          	sw	zero,-448(a5) # 80008870 <first.1688>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	b0c080e7          	jalr	-1268(ra) # 80003546 <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	13090913          	addi	s2,s2,304 # 80010b80 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	e1278793          	addi	a5,a5,-494 # 80008874 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	06893683          	ld	a3,104(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b84:	7528                	ld	a0,104(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0604b423          	sd	zero,104(s1)
  if(p->pagetable)
    80001b94:	70a8                	ld	a0,96(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	6cac                	ld	a1,88(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0604b023          	sd	zero,96(s1)
  p->sz = 0;
    80001ba6:	0404bc23          	sd	zero,88(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0404b423          	sd	zero,72(s1)
  p->name[0] = 0;
    80001bb2:	16048423          	sb	zero,360(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bdc:	0000f497          	auipc	s1,0xf
    80001be0:	3d448493          	addi	s1,s1,980 # 80010fb0 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	1cc90913          	addi	s2,s2,460 # 80016db0 <tickslock>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ffc080e7          	jalr	-4(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c04:	17848493          	addi	s1,s1,376
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a09d                	j	80001c74 <allocproc+0xa4>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  p->tickets = 10000;  
    80001c1e:	6789                	lui	a5,0x2
    80001c20:	7107879b          	addiw	a5,a5,1808
    80001c24:	d8dc                	sw	a5,52(s1)
  p->ticks = 0;
    80001c26:	0204ac23          	sw	zero,56(s1)
  p->pass = 0; 
    80001c2a:	0404a023          	sw	zero,64(s1)
  p->stride = 0;
    80001c2e:	0204ae23          	sw	zero,60(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	ec8080e7          	jalr	-312(ra) # 80000afa <kalloc>
    80001c3a:	892a                	mv	s2,a0
    80001c3c:	f4a8                	sd	a0,104(s1)
    80001c3e:	c131                	beqz	a0,80001c82 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c40:	8526                	mv	a0,s1
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	e48080e7          	jalr	-440(ra) # 80001a8a <proc_pagetable>
    80001c4a:	892a                	mv	s2,a0
    80001c4c:	f0a8                	sd	a0,96(s1)
  if(p->pagetable == 0){
    80001c4e:	c531                	beqz	a0,80001c9a <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c50:	07000613          	li	a2,112
    80001c54:	4581                	li	a1,0
    80001c56:	07048513          	addi	a0,s1,112
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	08c080e7          	jalr	140(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c62:	00000797          	auipc	a5,0x0
    80001c66:	d9c78793          	addi	a5,a5,-612 # 800019fe <forkret>
    80001c6a:	f8bc                	sd	a5,112(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c6c:	68bc                	ld	a5,80(s1)
    80001c6e:	6705                	lui	a4,0x1
    80001c70:	97ba                	add	a5,a5,a4
    80001c72:	fcbc                	sd	a5,120(s1)
}
    80001c74:	8526                	mv	a0,s1
    80001c76:	60e2                	ld	ra,24(sp)
    80001c78:	6442                	ld	s0,16(sp)
    80001c7a:	64a2                	ld	s1,8(sp)
    80001c7c:	6902                	ld	s2,0(sp)
    80001c7e:	6105                	addi	sp,sp,32
    80001c80:	8082                	ret
    freeproc(p);
    80001c82:	8526                	mv	a0,s1
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	ef4080e7          	jalr	-268(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	010080e7          	jalr	16(ra) # 80000c9e <release>
    return 0;
    80001c96:	84ca                	mv	s1,s2
    80001c98:	bff1                	j	80001c74 <allocproc+0xa4>
    freeproc(p);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	edc080e7          	jalr	-292(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	ff8080e7          	jalr	-8(ra) # 80000c9e <release>
    return 0;
    80001cae:	84ca                	mv	s1,s2
    80001cb0:	b7d1                	j	80001c74 <allocproc+0xa4>

0000000080001cb2 <userinit>:
{
    80001cb2:	1101                	addi	sp,sp,-32
    80001cb4:	ec06                	sd	ra,24(sp)
    80001cb6:	e822                	sd	s0,16(sp)
    80001cb8:	e426                	sd	s1,8(sp)
    80001cba:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	f14080e7          	jalr	-236(ra) # 80001bd0 <allocproc>
    80001cc4:	84aa                	mv	s1,a0
  initproc = p;
    80001cc6:	00007797          	auipc	a5,0x7
    80001cca:	c4a7b123          	sd	a0,-958(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cce:	03400613          	li	a2,52
    80001cd2:	00007597          	auipc	a1,0x7
    80001cd6:	bae58593          	addi	a1,a1,-1106 # 80008880 <initcode>
    80001cda:	7128                	ld	a0,96(a0)
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	696080e7          	jalr	1686(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001ce4:	6785                	lui	a5,0x1
    80001ce6:	ecbc                	sd	a5,88(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce8:	74b8                	ld	a4,104(s1)
    80001cea:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cee:	74b8                	ld	a4,104(s1)
    80001cf0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf2:	4641                	li	a2,16
    80001cf4:	00006597          	auipc	a1,0x6
    80001cf8:	50c58593          	addi	a1,a1,1292 # 80008200 <digits+0x1c0>
    80001cfc:	16848513          	addi	a0,s1,360
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	138080e7          	jalr	312(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d08:	00006517          	auipc	a0,0x6
    80001d0c:	50850513          	addi	a0,a0,1288 # 80008210 <digits+0x1d0>
    80001d10:	00002097          	auipc	ra,0x2
    80001d14:	258080e7          	jalr	600(ra) # 80003f68 <namei>
    80001d18:	16a4b023          	sd	a0,352(s1)
  p->state = RUNNABLE;
    80001d1c:	478d                	li	a5,3
    80001d1e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d20:	8526                	mv	a0,s1
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	f7c080e7          	jalr	-132(ra) # 80000c9e <release>
}
    80001d2a:	60e2                	ld	ra,24(sp)
    80001d2c:	6442                	ld	s0,16(sp)
    80001d2e:	64a2                	ld	s1,8(sp)
    80001d30:	6105                	addi	sp,sp,32
    80001d32:	8082                	ret

0000000080001d34 <growproc>:
{
    80001d34:	1101                	addi	sp,sp,-32
    80001d36:	ec06                	sd	ra,24(sp)
    80001d38:	e822                	sd	s0,16(sp)
    80001d3a:	e426                	sd	s1,8(sp)
    80001d3c:	e04a                	sd	s2,0(sp)
    80001d3e:	1000                	addi	s0,sp,32
    80001d40:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d42:	00000097          	auipc	ra,0x0
    80001d46:	c84080e7          	jalr	-892(ra) # 800019c6 <myproc>
    80001d4a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d4c:	6d2c                	ld	a1,88(a0)
  if(n > 0){
    80001d4e:	01204c63          	bgtz	s2,80001d66 <growproc+0x32>
  } else if(n < 0){
    80001d52:	02094663          	bltz	s2,80001d7e <growproc+0x4a>
  p->sz = sz;
    80001d56:	ecac                	sd	a1,88(s1)
  return 0;
    80001d58:	4501                	li	a0,0
}
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6902                	ld	s2,0(sp)
    80001d62:	6105                	addi	sp,sp,32
    80001d64:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d66:	4691                	li	a3,4
    80001d68:	00b90633          	add	a2,s2,a1
    80001d6c:	7128                	ld	a0,96(a0)
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	6be080e7          	jalr	1726(ra) # 8000142c <uvmalloc>
    80001d76:	85aa                	mv	a1,a0
    80001d78:	fd79                	bnez	a0,80001d56 <growproc+0x22>
      return -1;
    80001d7a:	557d                	li	a0,-1
    80001d7c:	bff9                	j	80001d5a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d7e:	00b90633          	add	a2,s2,a1
    80001d82:	7128                	ld	a0,96(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	660080e7          	jalr	1632(ra) # 800013e4 <uvmdealloc>
    80001d8c:	85aa                	mv	a1,a0
    80001d8e:	b7e1                	j	80001d56 <growproc+0x22>

0000000080001d90 <fork>:
{
    80001d90:	7179                	addi	sp,sp,-48
    80001d92:	f406                	sd	ra,40(sp)
    80001d94:	f022                	sd	s0,32(sp)
    80001d96:	ec26                	sd	s1,24(sp)
    80001d98:	e84a                	sd	s2,16(sp)
    80001d9a:	e44e                	sd	s3,8(sp)
    80001d9c:	e052                	sd	s4,0(sp)
    80001d9e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	c26080e7          	jalr	-986(ra) # 800019c6 <myproc>
    80001da8:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001daa:	00000097          	auipc	ra,0x0
    80001dae:	e26080e7          	jalr	-474(ra) # 80001bd0 <allocproc>
    80001db2:	10050b63          	beqz	a0,80001ec8 <fork+0x138>
    80001db6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001db8:	05893603          	ld	a2,88(s2)
    80001dbc:	712c                	ld	a1,96(a0)
    80001dbe:	06093503          	ld	a0,96(s2)
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	7be080e7          	jalr	1982(ra) # 80001580 <uvmcopy>
    80001dca:	04054663          	bltz	a0,80001e16 <fork+0x86>
  np->sz = p->sz;
    80001dce:	05893783          	ld	a5,88(s2)
    80001dd2:	04f9bc23          	sd	a5,88(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dd6:	06893683          	ld	a3,104(s2)
    80001dda:	87b6                	mv	a5,a3
    80001ddc:	0689b703          	ld	a4,104(s3)
    80001de0:	12068693          	addi	a3,a3,288
    80001de4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de8:	6788                	ld	a0,8(a5)
    80001dea:	6b8c                	ld	a1,16(a5)
    80001dec:	6f90                	ld	a2,24(a5)
    80001dee:	01073023          	sd	a6,0(a4)
    80001df2:	e708                	sd	a0,8(a4)
    80001df4:	eb0c                	sd	a1,16(a4)
    80001df6:	ef10                	sd	a2,24(a4)
    80001df8:	02078793          	addi	a5,a5,32
    80001dfc:	02070713          	addi	a4,a4,32
    80001e00:	fed792e3          	bne	a5,a3,80001de4 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e04:	0689b783          	ld	a5,104(s3)
    80001e08:	0607b823          	sd	zero,112(a5)
    80001e0c:	0e000493          	li	s1,224
  for(i = 0; i < NOFILE; i++)
    80001e10:	16000a13          	li	s4,352
    80001e14:	a03d                	j	80001e42 <fork+0xb2>
    freeproc(np);
    80001e16:	854e                	mv	a0,s3
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	d60080e7          	jalr	-672(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e20:	854e                	mv	a0,s3
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	e7c080e7          	jalr	-388(ra) # 80000c9e <release>
    return -1;
    80001e2a:	5a7d                	li	s4,-1
    80001e2c:	a069                	j	80001eb6 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e2e:	00002097          	auipc	ra,0x2
    80001e32:	7d0080e7          	jalr	2000(ra) # 800045fe <filedup>
    80001e36:	009987b3          	add	a5,s3,s1
    80001e3a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e3c:	04a1                	addi	s1,s1,8
    80001e3e:	01448763          	beq	s1,s4,80001e4c <fork+0xbc>
    if(p->ofile[i])
    80001e42:	009907b3          	add	a5,s2,s1
    80001e46:	6388                	ld	a0,0(a5)
    80001e48:	f17d                	bnez	a0,80001e2e <fork+0x9e>
    80001e4a:	bfcd                	j	80001e3c <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e4c:	16093503          	ld	a0,352(s2)
    80001e50:	00002097          	auipc	ra,0x2
    80001e54:	934080e7          	jalr	-1740(ra) # 80003784 <idup>
    80001e58:	16a9b023          	sd	a0,352(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5c:	4641                	li	a2,16
    80001e5e:	16890593          	addi	a1,s2,360
    80001e62:	16898513          	addi	a0,s3,360
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	fd2080e7          	jalr	-46(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e6e:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e72:	854e                	mv	a0,s3
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e2a080e7          	jalr	-470(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e7c:	0000f497          	auipc	s1,0xf
    80001e80:	d1c48493          	addi	s1,s1,-740 # 80010b98 <wait_lock>
    80001e84:	8526                	mv	a0,s1
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d64080e7          	jalr	-668(ra) # 80000bea <acquire>
  np->parent = p;
    80001e8e:	0529b423          	sd	s2,72(s3)
  release(&wait_lock);
    80001e92:	8526                	mv	a0,s1
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	e0a080e7          	jalr	-502(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001e9c:	854e                	mv	a0,s3
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	d4c080e7          	jalr	-692(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001ea6:	478d                	li	a5,3
    80001ea8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eac:	854e                	mv	a0,s3
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	df0080e7          	jalr	-528(ra) # 80000c9e <release>
}
    80001eb6:	8552                	mv	a0,s4
    80001eb8:	70a2                	ld	ra,40(sp)
    80001eba:	7402                	ld	s0,32(sp)
    80001ebc:	64e2                	ld	s1,24(sp)
    80001ebe:	6942                	ld	s2,16(sp)
    80001ec0:	69a2                	ld	s3,8(sp)
    80001ec2:	6a02                	ld	s4,0(sp)
    80001ec4:	6145                	addi	sp,sp,48
    80001ec6:	8082                	ret
    return -1;
    80001ec8:	5a7d                	li	s4,-1
    80001eca:	b7f5                	j	80001eb6 <fork+0x126>

0000000080001ecc <scheduler>:
{
    80001ecc:	715d                	addi	sp,sp,-80
    80001ece:	e486                	sd	ra,72(sp)
    80001ed0:	e0a2                	sd	s0,64(sp)
    80001ed2:	fc26                	sd	s1,56(sp)
    80001ed4:	f84a                	sd	s2,48(sp)
    80001ed6:	f44e                	sd	s3,40(sp)
    80001ed8:	f052                	sd	s4,32(sp)
    80001eda:	ec56                	sd	s5,24(sp)
    80001edc:	e85a                	sd	s6,16(sp)
    80001ede:	e45e                	sd	s7,8(sp)
    80001ee0:	e062                	sd	s8,0(sp)
    80001ee2:	0880                	addi	s0,sp,80
    80001ee4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ee8:	00779693          	slli	a3,a5,0x7
    80001eec:	0000f717          	auipc	a4,0xf
    80001ef0:	c9470713          	addi	a4,a4,-876 # 80010b80 <pid_lock>
    80001ef4:	9736                	add	a4,a4,a3
    80001ef6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &lowest_pass_p->context);
    80001efa:	0000f717          	auipc	a4,0xf
    80001efe:	cbe70713          	addi	a4,a4,-834 # 80010bb8 <cpus+0x8>
    80001f02:	00e68c33          	add	s8,a3,a4
      if (p->state == RUNNABLE) {
    80001f06:	4a0d                	li	s4,3
    for(p=proc; p < &proc[NPROC]; p++){
    80001f08:	00015a97          	auipc	s5,0x15
    80001f0c:	ea8a8a93          	addi	s5,s5,-344 # 80016db0 <tickslock>
    struct proc *lowest_pass_p = 0;
    80001f10:	4b01                	li	s6,0
        c->proc = lowest_pass_p;
    80001f12:	0000fb97          	auipc	s7,0xf
    80001f16:	c6eb8b93          	addi	s7,s7,-914 # 80010b80 <pid_lock>
    80001f1a:	9bb6                	add	s7,s7,a3
    80001f1c:	a81d                	j	80001f52 <scheduler+0x86>
          release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	d7e080e7          	jalr	-642(ra) # 80000c9e <release>
    80001f28:	a8ad                	j	80001fa2 <scheduler+0xd6>
          release(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	d72080e7          	jalr	-654(ra) # 80000c9e <release>
    for(p=proc; p < &proc[NPROC]; p++){
    80001f34:	17848793          	addi	a5,s1,376
    80001f38:	0757e963          	bltu	a5,s5,80001faa <scheduler+0xde>
    if(lowest_pass_p == 0) {
    80001f3c:	00098b63          	beqz	s3,80001f52 <scheduler+0x86>
      if(lowest_pass_p->state == RUNNABLE) {
    80001f40:	0189a783          	lw	a5,24(s3)
    80001f44:	03478363          	beq	a5,s4,80001f6a <scheduler+0x9e>
      release(&lowest_pass_p->lock);
    80001f48:	854e                	mv	a0,s3
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	d54080e7          	jalr	-684(ra) # 80000c9e <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f5a:	10079073          	csrw	sstatus,a5
    for(p=proc; p < &proc[NPROC]; p++){
    80001f5e:	0000f497          	auipc	s1,0xf
    80001f62:	05248493          	addi	s1,s1,82 # 80010fb0 <proc>
    struct proc *lowest_pass_p = 0;
    80001f66:	89da                	mv	s3,s6
    80001f68:	a099                	j	80001fae <scheduler+0xe2>
        lowest_pass_p->state = RUNNING;
    80001f6a:	4791                	li	a5,4
    80001f6c:	00f9ac23          	sw	a5,24(s3)
        c->proc = lowest_pass_p;
    80001f70:	033bb823          	sd	s3,48(s7)
        lowest_pass_p->pass += lowest_pass_p->stride;
    80001f74:	0409a783          	lw	a5,64(s3)
    80001f78:	03c9a703          	lw	a4,60(s3)
    80001f7c:	9fb9                	addw	a5,a5,a4
    80001f7e:	04f9a023          	sw	a5,64(s3)
        lowest_pass_p->ticks++;
    80001f82:	0389a783          	lw	a5,56(s3)
    80001f86:	2785                	addiw	a5,a5,1
    80001f88:	02f9ac23          	sw	a5,56(s3)
        swtch(&c->context, &lowest_pass_p->context);
    80001f8c:	07098593          	addi	a1,s3,112
    80001f90:	8562                	mv	a0,s8
    80001f92:	00000097          	auipc	ra,0x0
    80001f96:	756080e7          	jalr	1878(ra) # 800026e8 <swtch>
        c->proc = 0;
    80001f9a:	020bb823          	sd	zero,48(s7)
    80001f9e:	b76d                	j	80001f48 <scheduler+0x7c>
    80001fa0:	89a6                	mv	s3,s1
    for(p=proc; p < &proc[NPROC]; p++){
    80001fa2:	17848793          	addi	a5,s1,376
    80001fa6:	f957fde3          	bgeu	a5,s5,80001f40 <scheduler+0x74>
    80001faa:	17848493          	addi	s1,s1,376
      acquire(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	c3a080e7          	jalr	-966(ra) # 80000bea <acquire>
      if (p->state == RUNNABLE) {
    80001fb8:	4c9c                	lw	a5,24(s1)
    80001fba:	f74798e3          	bne	a5,s4,80001f2a <scheduler+0x5e>
        if (lowest_pass_p == 0 || lowest_pass_p->pass > p->pass) {
    80001fbe:	fe0981e3          	beqz	s3,80001fa0 <scheduler+0xd4>
    80001fc2:	0409a703          	lw	a4,64(s3)
    80001fc6:	40bc                	lw	a5,64(s1)
    80001fc8:	f4e7dbe3          	bge	a5,a4,80001f1e <scheduler+0x52>
            release(&lowest_pass_p->lock);
    80001fcc:	854e                	mv	a0,s3
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	cd0080e7          	jalr	-816(ra) # 80000c9e <release>
    80001fd6:	89a6                	mv	s3,s1
    80001fd8:	b7e9                	j	80001fa2 <scheduler+0xd6>

0000000080001fda <sched>:
{
    80001fda:	7179                	addi	sp,sp,-48
    80001fdc:	f406                	sd	ra,40(sp)
    80001fde:	f022                	sd	s0,32(sp)
    80001fe0:	ec26                	sd	s1,24(sp)
    80001fe2:	e84a                	sd	s2,16(sp)
    80001fe4:	e44e                	sd	s3,8(sp)
    80001fe6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	9de080e7          	jalr	-1570(ra) # 800019c6 <myproc>
    80001ff0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	b7e080e7          	jalr	-1154(ra) # 80000b70 <holding>
    80001ffa:	c93d                	beqz	a0,80002070 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ffc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	0000f717          	auipc	a4,0xf
    80002006:	b7e70713          	addi	a4,a4,-1154 # 80010b80 <pid_lock>
    8000200a:	97ba                	add	a5,a5,a4
    8000200c:	0a87a703          	lw	a4,168(a5)
    80002010:	4785                	li	a5,1
    80002012:	06f71763          	bne	a4,a5,80002080 <sched+0xa6>
  if(p->state == RUNNING)
    80002016:	4c98                	lw	a4,24(s1)
    80002018:	4791                	li	a5,4
    8000201a:	06f70b63          	beq	a4,a5,80002090 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002022:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002024:	efb5                	bnez	a5,800020a0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002026:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002028:	0000f917          	auipc	s2,0xf
    8000202c:	b5890913          	addi	s2,s2,-1192 # 80010b80 <pid_lock>
    80002030:	2781                	sext.w	a5,a5
    80002032:	079e                	slli	a5,a5,0x7
    80002034:	97ca                	add	a5,a5,s2
    80002036:	0ac7a983          	lw	s3,172(a5)
    8000203a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000203c:	2781                	sext.w	a5,a5
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	0000f597          	auipc	a1,0xf
    80002044:	b7858593          	addi	a1,a1,-1160 # 80010bb8 <cpus+0x8>
    80002048:	95be                	add	a1,a1,a5
    8000204a:	07048513          	addi	a0,s1,112
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	69a080e7          	jalr	1690(ra) # 800026e8 <swtch>
    80002056:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002058:	2781                	sext.w	a5,a5
    8000205a:	079e                	slli	a5,a5,0x7
    8000205c:	97ca                	add	a5,a5,s2
    8000205e:	0b37a623          	sw	s3,172(a5)
}
    80002062:	70a2                	ld	ra,40(sp)
    80002064:	7402                	ld	s0,32(sp)
    80002066:	64e2                	ld	s1,24(sp)
    80002068:	6942                	ld	s2,16(sp)
    8000206a:	69a2                	ld	s3,8(sp)
    8000206c:	6145                	addi	sp,sp,48
    8000206e:	8082                	ret
    panic("sched p->lock");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	1a850513          	addi	a0,a0,424 # 80008218 <digits+0x1d8>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4cc080e7          	jalr	1228(ra) # 80000544 <panic>
    panic("sched locks");
    80002080:	00006517          	auipc	a0,0x6
    80002084:	1a850513          	addi	a0,a0,424 # 80008228 <digits+0x1e8>
    80002088:	ffffe097          	auipc	ra,0xffffe
    8000208c:	4bc080e7          	jalr	1212(ra) # 80000544 <panic>
    panic("sched running");
    80002090:	00006517          	auipc	a0,0x6
    80002094:	1a850513          	addi	a0,a0,424 # 80008238 <digits+0x1f8>
    80002098:	ffffe097          	auipc	ra,0xffffe
    8000209c:	4ac080e7          	jalr	1196(ra) # 80000544 <panic>
    panic("sched interruptible");
    800020a0:	00006517          	auipc	a0,0x6
    800020a4:	1a850513          	addi	a0,a0,424 # 80008248 <digits+0x208>
    800020a8:	ffffe097          	auipc	ra,0xffffe
    800020ac:	49c080e7          	jalr	1180(ra) # 80000544 <panic>

00000000800020b0 <yield>:
{
    800020b0:	1101                	addi	sp,sp,-32
    800020b2:	ec06                	sd	ra,24(sp)
    800020b4:	e822                	sd	s0,16(sp)
    800020b6:	e426                	sd	s1,8(sp)
    800020b8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	90c080e7          	jalr	-1780(ra) # 800019c6 <myproc>
    800020c2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b26080e7          	jalr	-1242(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800020cc:	478d                	li	a5,3
    800020ce:	cc9c                	sw	a5,24(s1)
  sched();
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	f0a080e7          	jalr	-246(ra) # 80001fda <sched>
  release(&p->lock);
    800020d8:	8526                	mv	a0,s1
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	bc4080e7          	jalr	-1084(ra) # 80000c9e <release>
}
    800020e2:	60e2                	ld	ra,24(sp)
    800020e4:	6442                	ld	s0,16(sp)
    800020e6:	64a2                	ld	s1,8(sp)
    800020e8:	6105                	addi	sp,sp,32
    800020ea:	8082                	ret

00000000800020ec <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020ec:	7179                	addi	sp,sp,-48
    800020ee:	f406                	sd	ra,40(sp)
    800020f0:	f022                	sd	s0,32(sp)
    800020f2:	ec26                	sd	s1,24(sp)
    800020f4:	e84a                	sd	s2,16(sp)
    800020f6:	e44e                	sd	s3,8(sp)
    800020f8:	1800                	addi	s0,sp,48
    800020fa:	89aa                	mv	s3,a0
    800020fc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	8c8080e7          	jalr	-1848(ra) # 800019c6 <myproc>
    80002106:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	ae2080e7          	jalr	-1310(ra) # 80000bea <acquire>
  release(lk);
    80002110:	854a                	mv	a0,s2
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	b8c080e7          	jalr	-1140(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    8000211a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000211e:	4789                	li	a5,2
    80002120:	cc9c                	sw	a5,24(s1)
  //printf("%d sleeping.\n", p->pid);

  sched();
    80002122:	00000097          	auipc	ra,0x0
    80002126:	eb8080e7          	jalr	-328(ra) # 80001fda <sched>

  // Tidy up.
  p->chan = 0;
    8000212a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b6e080e7          	jalr	-1170(ra) # 80000c9e <release>
  acquire(lk);
    80002138:	854a                	mv	a0,s2
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	ab0080e7          	jalr	-1360(ra) # 80000bea <acquire>
}
    80002142:	70a2                	ld	ra,40(sp)
    80002144:	7402                	ld	s0,32(sp)
    80002146:	64e2                	ld	s1,24(sp)
    80002148:	6942                	ld	s2,16(sp)
    8000214a:	69a2                	ld	s3,8(sp)
    8000214c:	6145                	addi	sp,sp,48
    8000214e:	8082                	ret

0000000080002150 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002150:	7139                	addi	sp,sp,-64
    80002152:	fc06                	sd	ra,56(sp)
    80002154:	f822                	sd	s0,48(sp)
    80002156:	f426                	sd	s1,40(sp)
    80002158:	f04a                	sd	s2,32(sp)
    8000215a:	ec4e                	sd	s3,24(sp)
    8000215c:	e852                	sd	s4,16(sp)
    8000215e:	e456                	sd	s5,8(sp)
    80002160:	0080                	addi	s0,sp,64
    80002162:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002164:	0000f497          	auipc	s1,0xf
    80002168:	e4c48493          	addi	s1,s1,-436 # 80010fb0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000216c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000216e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002170:	00015917          	auipc	s2,0x15
    80002174:	c4090913          	addi	s2,s2,-960 # 80016db0 <tickslock>
    80002178:	a821                	j	80002190 <wakeup+0x40>
        p->state = RUNNABLE;
    8000217a:	0154ac23          	sw	s5,24(s1)
        //printf("%d wake up.\n", p->pid);
      }
      release(&p->lock);
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	b1e080e7          	jalr	-1250(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002188:	17848493          	addi	s1,s1,376
    8000218c:	03248463          	beq	s1,s2,800021b4 <wakeup+0x64>
    if(p != myproc()){
    80002190:	00000097          	auipc	ra,0x0
    80002194:	836080e7          	jalr	-1994(ra) # 800019c6 <myproc>
    80002198:	fea488e3          	beq	s1,a0,80002188 <wakeup+0x38>
      acquire(&p->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	a4c080e7          	jalr	-1460(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021a6:	4c9c                	lw	a5,24(s1)
    800021a8:	fd379be3          	bne	a5,s3,8000217e <wakeup+0x2e>
    800021ac:	709c                	ld	a5,32(s1)
    800021ae:	fd4798e3          	bne	a5,s4,8000217e <wakeup+0x2e>
    800021b2:	b7e1                	j	8000217a <wakeup+0x2a>
    }
  }
}
    800021b4:	70e2                	ld	ra,56(sp)
    800021b6:	7442                	ld	s0,48(sp)
    800021b8:	74a2                	ld	s1,40(sp)
    800021ba:	7902                	ld	s2,32(sp)
    800021bc:	69e2                	ld	s3,24(sp)
    800021be:	6a42                	ld	s4,16(sp)
    800021c0:	6aa2                	ld	s5,8(sp)
    800021c2:	6121                	addi	sp,sp,64
    800021c4:	8082                	ret

00000000800021c6 <reparent>:
{
    800021c6:	7179                	addi	sp,sp,-48
    800021c8:	f406                	sd	ra,40(sp)
    800021ca:	f022                	sd	s0,32(sp)
    800021cc:	ec26                	sd	s1,24(sp)
    800021ce:	e84a                	sd	s2,16(sp)
    800021d0:	e44e                	sd	s3,8(sp)
    800021d2:	e052                	sd	s4,0(sp)
    800021d4:	1800                	addi	s0,sp,48
    800021d6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021d8:	0000f497          	auipc	s1,0xf
    800021dc:	dd848493          	addi	s1,s1,-552 # 80010fb0 <proc>
      pp->parent = initproc;
    800021e0:	00006a17          	auipc	s4,0x6
    800021e4:	728a0a13          	addi	s4,s4,1832 # 80008908 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e8:	00015997          	auipc	s3,0x15
    800021ec:	bc898993          	addi	s3,s3,-1080 # 80016db0 <tickslock>
    800021f0:	a029                	j	800021fa <reparent+0x34>
    800021f2:	17848493          	addi	s1,s1,376
    800021f6:	01348d63          	beq	s1,s3,80002210 <reparent+0x4a>
    if(pp->parent == p){
    800021fa:	64bc                	ld	a5,72(s1)
    800021fc:	ff279be3          	bne	a5,s2,800021f2 <reparent+0x2c>
      pp->parent = initproc;
    80002200:	000a3503          	ld	a0,0(s4)
    80002204:	e4a8                	sd	a0,72(s1)
      wakeup(initproc);
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	f4a080e7          	jalr	-182(ra) # 80002150 <wakeup>
    8000220e:	b7d5                	j	800021f2 <reparent+0x2c>
}
    80002210:	70a2                	ld	ra,40(sp)
    80002212:	7402                	ld	s0,32(sp)
    80002214:	64e2                	ld	s1,24(sp)
    80002216:	6942                	ld	s2,16(sp)
    80002218:	69a2                	ld	s3,8(sp)
    8000221a:	6a02                	ld	s4,0(sp)
    8000221c:	6145                	addi	sp,sp,48
    8000221e:	8082                	ret

0000000080002220 <exit>:
{
    80002220:	7179                	addi	sp,sp,-48
    80002222:	f406                	sd	ra,40(sp)
    80002224:	f022                	sd	s0,32(sp)
    80002226:	ec26                	sd	s1,24(sp)
    80002228:	e84a                	sd	s2,16(sp)
    8000222a:	e44e                	sd	s3,8(sp)
    8000222c:	e052                	sd	s4,0(sp)
    8000222e:	1800                	addi	s0,sp,48
    80002230:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	794080e7          	jalr	1940(ra) # 800019c6 <myproc>
    8000223a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000223c:	00006797          	auipc	a5,0x6
    80002240:	6cc7b783          	ld	a5,1740(a5) # 80008908 <initproc>
    80002244:	0e050493          	addi	s1,a0,224
    80002248:	16050913          	addi	s2,a0,352
    8000224c:	02a79363          	bne	a5,a0,80002272 <exit+0x52>
    panic("init exiting");
    80002250:	00006517          	auipc	a0,0x6
    80002254:	01050513          	addi	a0,a0,16 # 80008260 <digits+0x220>
    80002258:	ffffe097          	auipc	ra,0xffffe
    8000225c:	2ec080e7          	jalr	748(ra) # 80000544 <panic>
      fileclose(f);
    80002260:	00002097          	auipc	ra,0x2
    80002264:	3f0080e7          	jalr	1008(ra) # 80004650 <fileclose>
      p->ofile[fd] = 0;
    80002268:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000226c:	04a1                	addi	s1,s1,8
    8000226e:	01248563          	beq	s1,s2,80002278 <exit+0x58>
    if(p->ofile[fd]){
    80002272:	6088                	ld	a0,0(s1)
    80002274:	f575                	bnez	a0,80002260 <exit+0x40>
    80002276:	bfdd                	j	8000226c <exit+0x4c>
  begin_op();
    80002278:	00002097          	auipc	ra,0x2
    8000227c:	f0c080e7          	jalr	-244(ra) # 80004184 <begin_op>
  iput(p->cwd);
    80002280:	1609b503          	ld	a0,352(s3)
    80002284:	00001097          	auipc	ra,0x1
    80002288:	6f8080e7          	jalr	1784(ra) # 8000397c <iput>
  end_op();
    8000228c:	00002097          	auipc	ra,0x2
    80002290:	f78080e7          	jalr	-136(ra) # 80004204 <end_op>
  p->cwd = 0;
    80002294:	1609b023          	sd	zero,352(s3)
  acquire(&wait_lock);
    80002298:	0000f497          	auipc	s1,0xf
    8000229c:	90048493          	addi	s1,s1,-1792 # 80010b98 <wait_lock>
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	948080e7          	jalr	-1720(ra) # 80000bea <acquire>
  reparent(p);
    800022aa:	854e                	mv	a0,s3
    800022ac:	00000097          	auipc	ra,0x0
    800022b0:	f1a080e7          	jalr	-230(ra) # 800021c6 <reparent>
  wakeup(p->parent);
    800022b4:	0489b503          	ld	a0,72(s3)
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	e98080e7          	jalr	-360(ra) # 80002150 <wakeup>
  acquire(&p->lock);
    800022c0:	854e                	mv	a0,s3
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	928080e7          	jalr	-1752(ra) # 80000bea <acquire>
  p->xstate = status;
    800022ca:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022ce:	4795                	li	a5,5
    800022d0:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	9c8080e7          	jalr	-1592(ra) # 80000c9e <release>
  sched();
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	cfc080e7          	jalr	-772(ra) # 80001fda <sched>
  panic("zombie exit");
    800022e6:	00006517          	auipc	a0,0x6
    800022ea:	f8a50513          	addi	a0,a0,-118 # 80008270 <digits+0x230>
    800022ee:	ffffe097          	auipc	ra,0xffffe
    800022f2:	256080e7          	jalr	598(ra) # 80000544 <panic>

00000000800022f6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022f6:	7179                	addi	sp,sp,-48
    800022f8:	f406                	sd	ra,40(sp)
    800022fa:	f022                	sd	s0,32(sp)
    800022fc:	ec26                	sd	s1,24(sp)
    800022fe:	e84a                	sd	s2,16(sp)
    80002300:	e44e                	sd	s3,8(sp)
    80002302:	1800                	addi	s0,sp,48
    80002304:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002306:	0000f497          	auipc	s1,0xf
    8000230a:	caa48493          	addi	s1,s1,-854 # 80010fb0 <proc>
    8000230e:	00015997          	auipc	s3,0x15
    80002312:	aa298993          	addi	s3,s3,-1374 # 80016db0 <tickslock>
    acquire(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	8d2080e7          	jalr	-1838(ra) # 80000bea <acquire>
    if(p->pid == pid){
    80002320:	589c                	lw	a5,48(s1)
    80002322:	01278d63          	beq	a5,s2,8000233c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	976080e7          	jalr	-1674(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002330:	17848493          	addi	s1,s1,376
    80002334:	ff3491e3          	bne	s1,s3,80002316 <kill+0x20>
  }
  return -1;
    80002338:	557d                	li	a0,-1
    8000233a:	a829                	j	80002354 <kill+0x5e>
      p->killed = 1;
    8000233c:	4785                	li	a5,1
    8000233e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002340:	4c98                	lw	a4,24(s1)
    80002342:	4789                	li	a5,2
    80002344:	00f70f63          	beq	a4,a5,80002362 <kill+0x6c>
      release(&p->lock);
    80002348:	8526                	mv	a0,s1
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	954080e7          	jalr	-1708(ra) # 80000c9e <release>
      return 0;
    80002352:	4501                	li	a0,0
}
    80002354:	70a2                	ld	ra,40(sp)
    80002356:	7402                	ld	s0,32(sp)
    80002358:	64e2                	ld	s1,24(sp)
    8000235a:	6942                	ld	s2,16(sp)
    8000235c:	69a2                	ld	s3,8(sp)
    8000235e:	6145                	addi	sp,sp,48
    80002360:	8082                	ret
        p->state = RUNNABLE;
    80002362:	478d                	li	a5,3
    80002364:	cc9c                	sw	a5,24(s1)
    80002366:	b7cd                	j	80002348 <kill+0x52>

0000000080002368 <setkilled>:

void
setkilled(struct proc *p)
{
    80002368:	1101                	addi	sp,sp,-32
    8000236a:	ec06                	sd	ra,24(sp)
    8000236c:	e822                	sd	s0,16(sp)
    8000236e:	e426                	sd	s1,8(sp)
    80002370:	1000                	addi	s0,sp,32
    80002372:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	876080e7          	jalr	-1930(ra) # 80000bea <acquire>
  p->killed = 1;
    8000237c:	4785                	li	a5,1
    8000237e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	91c080e7          	jalr	-1764(ra) # 80000c9e <release>
}
    8000238a:	60e2                	ld	ra,24(sp)
    8000238c:	6442                	ld	s0,16(sp)
    8000238e:	64a2                	ld	s1,8(sp)
    80002390:	6105                	addi	sp,sp,32
    80002392:	8082                	ret

0000000080002394 <killed>:

int
killed(struct proc *p)
{
    80002394:	1101                	addi	sp,sp,-32
    80002396:	ec06                	sd	ra,24(sp)
    80002398:	e822                	sd	s0,16(sp)
    8000239a:	e426                	sd	s1,8(sp)
    8000239c:	e04a                	sd	s2,0(sp)
    8000239e:	1000                	addi	s0,sp,32
    800023a0:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	848080e7          	jalr	-1976(ra) # 80000bea <acquire>
  k = p->killed;
    800023aa:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8ee080e7          	jalr	-1810(ra) # 80000c9e <release>
  return k;
}
    800023b8:	854a                	mv	a0,s2
    800023ba:	60e2                	ld	ra,24(sp)
    800023bc:	6442                	ld	s0,16(sp)
    800023be:	64a2                	ld	s1,8(sp)
    800023c0:	6902                	ld	s2,0(sp)
    800023c2:	6105                	addi	sp,sp,32
    800023c4:	8082                	ret

00000000800023c6 <wait>:
{
    800023c6:	715d                	addi	sp,sp,-80
    800023c8:	e486                	sd	ra,72(sp)
    800023ca:	e0a2                	sd	s0,64(sp)
    800023cc:	fc26                	sd	s1,56(sp)
    800023ce:	f84a                	sd	s2,48(sp)
    800023d0:	f44e                	sd	s3,40(sp)
    800023d2:	f052                	sd	s4,32(sp)
    800023d4:	ec56                	sd	s5,24(sp)
    800023d6:	e85a                	sd	s6,16(sp)
    800023d8:	e45e                	sd	s7,8(sp)
    800023da:	e062                	sd	s8,0(sp)
    800023dc:	0880                	addi	s0,sp,80
    800023de:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	5e6080e7          	jalr	1510(ra) # 800019c6 <myproc>
    800023e8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023ea:	0000e517          	auipc	a0,0xe
    800023ee:	7ae50513          	addi	a0,a0,1966 # 80010b98 <wait_lock>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	7f8080e7          	jalr	2040(ra) # 80000bea <acquire>
    havekids = 0;
    800023fa:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023fc:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023fe:	00015997          	auipc	s3,0x15
    80002402:	9b298993          	addi	s3,s3,-1614 # 80016db0 <tickslock>
        havekids = 1;
    80002406:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002408:	0000ec17          	auipc	s8,0xe
    8000240c:	790c0c13          	addi	s8,s8,1936 # 80010b98 <wait_lock>
    havekids = 0;
    80002410:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002412:	0000f497          	auipc	s1,0xf
    80002416:	b9e48493          	addi	s1,s1,-1122 # 80010fb0 <proc>
    8000241a:	a0bd                	j	80002488 <wait+0xc2>
          pid = pp->pid;
    8000241c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002420:	000b0e63          	beqz	s6,8000243c <wait+0x76>
    80002424:	4691                	li	a3,4
    80002426:	02c48613          	addi	a2,s1,44
    8000242a:	85da                	mv	a1,s6
    8000242c:	06093503          	ld	a0,96(s2)
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	254080e7          	jalr	596(ra) # 80001684 <copyout>
    80002438:	02054563          	bltz	a0,80002462 <wait+0x9c>
          freeproc(pp);
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	73a080e7          	jalr	1850(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	856080e7          	jalr	-1962(ra) # 80000c9e <release>
          release(&wait_lock);
    80002450:	0000e517          	auipc	a0,0xe
    80002454:	74850513          	addi	a0,a0,1864 # 80010b98 <wait_lock>
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	846080e7          	jalr	-1978(ra) # 80000c9e <release>
          return pid;
    80002460:	a0b5                	j	800024cc <wait+0x106>
            release(&pp->lock);
    80002462:	8526                	mv	a0,s1
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	83a080e7          	jalr	-1990(ra) # 80000c9e <release>
            release(&wait_lock);
    8000246c:	0000e517          	auipc	a0,0xe
    80002470:	72c50513          	addi	a0,a0,1836 # 80010b98 <wait_lock>
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	82a080e7          	jalr	-2006(ra) # 80000c9e <release>
            return -1;
    8000247c:	59fd                	li	s3,-1
    8000247e:	a0b9                	j	800024cc <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002480:	17848493          	addi	s1,s1,376
    80002484:	03348463          	beq	s1,s3,800024ac <wait+0xe6>
      if(pp->parent == p){
    80002488:	64bc                	ld	a5,72(s1)
    8000248a:	ff279be3          	bne	a5,s2,80002480 <wait+0xba>
        acquire(&pp->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	75a080e7          	jalr	1882(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002498:	4c9c                	lw	a5,24(s1)
    8000249a:	f94781e3          	beq	a5,s4,8000241c <wait+0x56>
        release(&pp->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7fe080e7          	jalr	2046(ra) # 80000c9e <release>
        havekids = 1;
    800024a8:	8756                	mv	a4,s5
    800024aa:	bfd9                	j	80002480 <wait+0xba>
    if(!havekids || killed(p)){
    800024ac:	c719                	beqz	a4,800024ba <wait+0xf4>
    800024ae:	854a                	mv	a0,s2
    800024b0:	00000097          	auipc	ra,0x0
    800024b4:	ee4080e7          	jalr	-284(ra) # 80002394 <killed>
    800024b8:	c51d                	beqz	a0,800024e6 <wait+0x120>
      release(&wait_lock);
    800024ba:	0000e517          	auipc	a0,0xe
    800024be:	6de50513          	addi	a0,a0,1758 # 80010b98 <wait_lock>
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	7dc080e7          	jalr	2012(ra) # 80000c9e <release>
      return -1;
    800024ca:	59fd                	li	s3,-1
}
    800024cc:	854e                	mv	a0,s3
    800024ce:	60a6                	ld	ra,72(sp)
    800024d0:	6406                	ld	s0,64(sp)
    800024d2:	74e2                	ld	s1,56(sp)
    800024d4:	7942                	ld	s2,48(sp)
    800024d6:	79a2                	ld	s3,40(sp)
    800024d8:	7a02                	ld	s4,32(sp)
    800024da:	6ae2                	ld	s5,24(sp)
    800024dc:	6b42                	ld	s6,16(sp)
    800024de:	6ba2                	ld	s7,8(sp)
    800024e0:	6c02                	ld	s8,0(sp)
    800024e2:	6161                	addi	sp,sp,80
    800024e4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024e6:	85e2                	mv	a1,s8
    800024e8:	854a                	mv	a0,s2
    800024ea:	00000097          	auipc	ra,0x0
    800024ee:	c02080e7          	jalr	-1022(ra) # 800020ec <sleep>
    havekids = 0;
    800024f2:	bf39                	j	80002410 <wait+0x4a>

00000000800024f4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024f4:	7179                	addi	sp,sp,-48
    800024f6:	f406                	sd	ra,40(sp)
    800024f8:	f022                	sd	s0,32(sp)
    800024fa:	ec26                	sd	s1,24(sp)
    800024fc:	e84a                	sd	s2,16(sp)
    800024fe:	e44e                	sd	s3,8(sp)
    80002500:	e052                	sd	s4,0(sp)
    80002502:	1800                	addi	s0,sp,48
    80002504:	84aa                	mv	s1,a0
    80002506:	892e                	mv	s2,a1
    80002508:	89b2                	mv	s3,a2
    8000250a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	4ba080e7          	jalr	1210(ra) # 800019c6 <myproc>
  if(user_dst){
    80002514:	c08d                	beqz	s1,80002536 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002516:	86d2                	mv	a3,s4
    80002518:	864e                	mv	a2,s3
    8000251a:	85ca                	mv	a1,s2
    8000251c:	7128                	ld	a0,96(a0)
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	166080e7          	jalr	358(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002526:	70a2                	ld	ra,40(sp)
    80002528:	7402                	ld	s0,32(sp)
    8000252a:	64e2                	ld	s1,24(sp)
    8000252c:	6942                	ld	s2,16(sp)
    8000252e:	69a2                	ld	s3,8(sp)
    80002530:	6a02                	ld	s4,0(sp)
    80002532:	6145                	addi	sp,sp,48
    80002534:	8082                	ret
    memmove((char *)dst, src, len);
    80002536:	000a061b          	sext.w	a2,s4
    8000253a:	85ce                	mv	a1,s3
    8000253c:	854a                	mv	a0,s2
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	808080e7          	jalr	-2040(ra) # 80000d46 <memmove>
    return 0;
    80002546:	8526                	mv	a0,s1
    80002548:	bff9                	j	80002526 <either_copyout+0x32>

000000008000254a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	e052                	sd	s4,0(sp)
    80002558:	1800                	addi	s0,sp,48
    8000255a:	892a                	mv	s2,a0
    8000255c:	84ae                	mv	s1,a1
    8000255e:	89b2                	mv	s3,a2
    80002560:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	464080e7          	jalr	1124(ra) # 800019c6 <myproc>
  if(user_src){
    8000256a:	c08d                	beqz	s1,8000258c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000256c:	86d2                	mv	a3,s4
    8000256e:	864e                	mv	a2,s3
    80002570:	85ca                	mv	a1,s2
    80002572:	7128                	ld	a0,96(a0)
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	19c080e7          	jalr	412(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000257c:	70a2                	ld	ra,40(sp)
    8000257e:	7402                	ld	s0,32(sp)
    80002580:	64e2                	ld	s1,24(sp)
    80002582:	6942                	ld	s2,16(sp)
    80002584:	69a2                	ld	s3,8(sp)
    80002586:	6a02                	ld	s4,0(sp)
    80002588:	6145                	addi	sp,sp,48
    8000258a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000258c:	000a061b          	sext.w	a2,s4
    80002590:	85ce                	mv	a1,s3
    80002592:	854a                	mv	a0,s2
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	7b2080e7          	jalr	1970(ra) # 80000d46 <memmove>
    return 0;
    8000259c:	8526                	mv	a0,s1
    8000259e:	bff9                	j	8000257c <either_copyin+0x32>

00000000800025a0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025a0:	715d                	addi	sp,sp,-80
    800025a2:	e486                	sd	ra,72(sp)
    800025a4:	e0a2                	sd	s0,64(sp)
    800025a6:	fc26                	sd	s1,56(sp)
    800025a8:	f84a                	sd	s2,48(sp)
    800025aa:	f44e                	sd	s3,40(sp)
    800025ac:	f052                	sd	s4,32(sp)
    800025ae:	ec56                	sd	s5,24(sp)
    800025b0:	e85a                	sd	s6,16(sp)
    800025b2:	e45e                	sd	s7,8(sp)
    800025b4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025b6:	00006517          	auipc	a0,0x6
    800025ba:	b1250513          	addi	a0,a0,-1262 # 800080c8 <digits+0x88>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	fd0080e7          	jalr	-48(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c6:	0000f497          	auipc	s1,0xf
    800025ca:	b5248493          	addi	s1,s1,-1198 # 80011118 <proc+0x168>
    800025ce:	00015917          	auipc	s2,0x15
    800025d2:	94a90913          	addi	s2,s2,-1718 # 80016f18 <bcache+0x150>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025d8:	00006997          	auipc	s3,0x6
    800025dc:	ca898993          	addi	s3,s3,-856 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025e0:	00006a97          	auipc	s5,0x6
    800025e4:	ca8a8a93          	addi	s5,s5,-856 # 80008288 <digits+0x248>
    printf("\n");
    800025e8:	00006a17          	auipc	s4,0x6
    800025ec:	ae0a0a13          	addi	s4,s4,-1312 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f0:	00006b97          	auipc	s7,0x6
    800025f4:	cf8b8b93          	addi	s7,s7,-776 # 800082e8 <states.1732>
    800025f8:	a00d                	j	8000261a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025fa:	ec86a583          	lw	a1,-312(a3)
    800025fe:	8556                	mv	a0,s5
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	f8e080e7          	jalr	-114(ra) # 8000058e <printf>
    printf("\n");
    80002608:	8552                	mv	a0,s4
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	f84080e7          	jalr	-124(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002612:	17848493          	addi	s1,s1,376
    80002616:	03248163          	beq	s1,s2,80002638 <procdump+0x98>
    if(p->state == UNUSED)
    8000261a:	86a6                	mv	a3,s1
    8000261c:	eb04a783          	lw	a5,-336(s1)
    80002620:	dbed                	beqz	a5,80002612 <procdump+0x72>
      state = "???";
    80002622:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002624:	fcfb6be3          	bltu	s6,a5,800025fa <procdump+0x5a>
    80002628:	1782                	slli	a5,a5,0x20
    8000262a:	9381                	srli	a5,a5,0x20
    8000262c:	078e                	slli	a5,a5,0x3
    8000262e:	97de                	add	a5,a5,s7
    80002630:	6390                	ld	a2,0(a5)
    80002632:	f661                	bnez	a2,800025fa <procdump+0x5a>
      state = "???";
    80002634:	864e                	mv	a2,s3
    80002636:	b7d1                	j	800025fa <procdump+0x5a>
  }
}
    80002638:	60a6                	ld	ra,72(sp)
    8000263a:	6406                	ld	s0,64(sp)
    8000263c:	74e2                	ld	s1,56(sp)
    8000263e:	7942                	ld	s2,48(sp)
    80002640:	79a2                	ld	s3,40(sp)
    80002642:	7a02                	ld	s4,32(sp)
    80002644:	6ae2                	ld	s5,24(sp)
    80002646:	6b42                	ld	s6,16(sp)
    80002648:	6ba2                	ld	s7,8(sp)
    8000264a:	6161                	addi	sp,sp,80
    8000264c:	8082                	ret

000000008000264e <sched_statistics>:

int 
sched_statistics(void)
{
    8000264e:	7179                	addi	sp,sp,-48
    80002650:	f406                	sd	ra,40(sp)
    80002652:	f022                	sd	s0,32(sp)
    80002654:	ec26                	sd	s1,24(sp)
    80002656:	e84a                	sd	s2,16(sp)
    80002658:	e44e                	sd	s3,8(sp)
    8000265a:	1800                	addi	s0,sp,48
  struct proc *p;
  //printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    8000265c:	0000f497          	auipc	s1,0xf
    80002660:	95448493          	addi	s1,s1,-1708 # 80010fb0 <proc>
    if(p->state != UNUSED){
      printf("%d(%s): tickets: %d, ticks: %d\n", p->pid, p->name, p->tickets, p->ticks);
    80002664:	00006997          	auipc	s3,0x6
    80002668:	c3498993          	addi	s3,s3,-972 # 80008298 <digits+0x258>
  for(p = proc; p < &proc[NPROC]; p++){
    8000266c:	00014917          	auipc	s2,0x14
    80002670:	74490913          	addi	s2,s2,1860 # 80016db0 <tickslock>
    80002674:	a839                	j	80002692 <sched_statistics+0x44>
      printf("%d(%s): tickets: %d, ticks: %d\n", p->pid, p->name, p->tickets, p->ticks);
    80002676:	5c98                	lw	a4,56(s1)
    80002678:	58d4                	lw	a3,52(s1)
    8000267a:	16848613          	addi	a2,s1,360
    8000267e:	588c                	lw	a1,48(s1)
    80002680:	854e                	mv	a0,s3
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	f0c080e7          	jalr	-244(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000268a:	17848493          	addi	s1,s1,376
    8000268e:	01248563          	beq	s1,s2,80002698 <sched_statistics+0x4a>
    if(p->state != UNUSED){
    80002692:	4c9c                	lw	a5,24(s1)
    80002694:	dbfd                	beqz	a5,8000268a <sched_statistics+0x3c>
    80002696:	b7c5                	j	80002676 <sched_statistics+0x28>
    }
  }
  return 0;
}
    80002698:	4501                	li	a0,0
    8000269a:	70a2                	ld	ra,40(sp)
    8000269c:	7402                	ld	s0,32(sp)
    8000269e:	64e2                	ld	s1,24(sp)
    800026a0:	6942                	ld	s2,16(sp)
    800026a2:	69a2                	ld	s3,8(sp)
    800026a4:	6145                	addi	sp,sp,48
    800026a6:	8082                	ret

00000000800026a8 <sched_tickets>:

int
sched_tickets(int n)
{
    800026a8:	1101                	addi	sp,sp,-32
    800026aa:	ec06                	sd	ra,24(sp)
    800026ac:	e822                	sd	s0,16(sp)
    800026ae:	e426                	sd	s1,8(sp)
    800026b0:	1000                	addi	s0,sp,32
    800026b2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800026b4:	fffff097          	auipc	ra,0xfffff
    800026b8:	312080e7          	jalr	786(ra) # 800019c6 <myproc>
  if(n > 10000)
    800026bc:	8726                	mv	a4,s1
    800026be:	6789                	lui	a5,0x2
    800026c0:	71078793          	addi	a5,a5,1808 # 2710 <_entry-0x7fffd8f0>
    800026c4:	0097d563          	bge	a5,s1,800026ce <sched_tickets+0x26>
    800026c8:	6789                	lui	a5,0x2
    800026ca:	7107871b          	addiw	a4,a5,1808
    n = 10000;
  p->tickets = n;
    800026ce:	d958                	sw	a4,52(a0)
  p->stride = BIG_NUM / p->tickets;
    800026d0:	67e1                	lui	a5,0x18
    800026d2:	6a07879b          	addiw	a5,a5,1696
    800026d6:	02e7c7bb          	divw	a5,a5,a4
    800026da:	dd5c                	sw	a5,60(a0)
  //printf("sched_tickets: pid %d set tickets = %d, stride = %d\n", p->pid, p->tickets, p->stride);
  return 0;
    800026dc:	4501                	li	a0,0
    800026de:	60e2                	ld	ra,24(sp)
    800026e0:	6442                	ld	s0,16(sp)
    800026e2:	64a2                	ld	s1,8(sp)
    800026e4:	6105                	addi	sp,sp,32
    800026e6:	8082                	ret

00000000800026e8 <swtch>:
    800026e8:	00153023          	sd	ra,0(a0)
    800026ec:	00253423          	sd	sp,8(a0)
    800026f0:	e900                	sd	s0,16(a0)
    800026f2:	ed04                	sd	s1,24(a0)
    800026f4:	03253023          	sd	s2,32(a0)
    800026f8:	03353423          	sd	s3,40(a0)
    800026fc:	03453823          	sd	s4,48(a0)
    80002700:	03553c23          	sd	s5,56(a0)
    80002704:	05653023          	sd	s6,64(a0)
    80002708:	05753423          	sd	s7,72(a0)
    8000270c:	05853823          	sd	s8,80(a0)
    80002710:	05953c23          	sd	s9,88(a0)
    80002714:	07a53023          	sd	s10,96(a0)
    80002718:	07b53423          	sd	s11,104(a0)
    8000271c:	0005b083          	ld	ra,0(a1)
    80002720:	0085b103          	ld	sp,8(a1)
    80002724:	6980                	ld	s0,16(a1)
    80002726:	6d84                	ld	s1,24(a1)
    80002728:	0205b903          	ld	s2,32(a1)
    8000272c:	0285b983          	ld	s3,40(a1)
    80002730:	0305ba03          	ld	s4,48(a1)
    80002734:	0385ba83          	ld	s5,56(a1)
    80002738:	0405bb03          	ld	s6,64(a1)
    8000273c:	0485bb83          	ld	s7,72(a1)
    80002740:	0505bc03          	ld	s8,80(a1)
    80002744:	0585bc83          	ld	s9,88(a1)
    80002748:	0605bd03          	ld	s10,96(a1)
    8000274c:	0685bd83          	ld	s11,104(a1)
    80002750:	8082                	ret

0000000080002752 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002752:	1141                	addi	sp,sp,-16
    80002754:	e406                	sd	ra,8(sp)
    80002756:	e022                	sd	s0,0(sp)
    80002758:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000275a:	00006597          	auipc	a1,0x6
    8000275e:	bbe58593          	addi	a1,a1,-1090 # 80008318 <states.1732+0x30>
    80002762:	00014517          	auipc	a0,0x14
    80002766:	64e50513          	addi	a0,a0,1614 # 80016db0 <tickslock>
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	3f0080e7          	jalr	1008(ra) # 80000b5a <initlock>
}
    80002772:	60a2                	ld	ra,8(sp)
    80002774:	6402                	ld	s0,0(sp)
    80002776:	0141                	addi	sp,sp,16
    80002778:	8082                	ret

000000008000277a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000277a:	1141                	addi	sp,sp,-16
    8000277c:	e422                	sd	s0,8(sp)
    8000277e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002780:	00003797          	auipc	a5,0x3
    80002784:	51078793          	addi	a5,a5,1296 # 80005c90 <kernelvec>
    80002788:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000278c:	6422                	ld	s0,8(sp)
    8000278e:	0141                	addi	sp,sp,16
    80002790:	8082                	ret

0000000080002792 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002792:	1141                	addi	sp,sp,-16
    80002794:	e406                	sd	ra,8(sp)
    80002796:	e022                	sd	s0,0(sp)
    80002798:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	22c080e7          	jalr	556(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027a2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027a6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027a8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027ac:	00005617          	auipc	a2,0x5
    800027b0:	85460613          	addi	a2,a2,-1964 # 80007000 <_trampoline>
    800027b4:	00005697          	auipc	a3,0x5
    800027b8:	84c68693          	addi	a3,a3,-1972 # 80007000 <_trampoline>
    800027bc:	8e91                	sub	a3,a3,a2
    800027be:	040007b7          	lui	a5,0x4000
    800027c2:	17fd                	addi	a5,a5,-1
    800027c4:	07b2                	slli	a5,a5,0xc
    800027c6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027c8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027cc:	7538                	ld	a4,104(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027ce:	180026f3          	csrr	a3,satp
    800027d2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027d4:	7538                	ld	a4,104(a0)
    800027d6:	6934                	ld	a3,80(a0)
    800027d8:	6585                	lui	a1,0x1
    800027da:	96ae                	add	a3,a3,a1
    800027dc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027de:	7538                	ld	a4,104(a0)
    800027e0:	00000697          	auipc	a3,0x0
    800027e4:	15268693          	addi	a3,a3,338 # 80002932 <usertrap>
    800027e8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027ea:	7538                	ld	a4,104(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027ec:	8692                	mv	a3,tp
    800027ee:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027f4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027f8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027fc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002800:	7538                	ld	a4,104(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002802:	6f18                	ld	a4,24(a4)
    80002804:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002808:	7128                	ld	a0,96(a0)
    8000280a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000280c:	00005717          	auipc	a4,0x5
    80002810:	89070713          	addi	a4,a4,-1904 # 8000709c <userret>
    80002814:	8f11                	sub	a4,a4,a2
    80002816:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002818:	577d                	li	a4,-1
    8000281a:	177e                	slli	a4,a4,0x3f
    8000281c:	8d59                	or	a0,a0,a4
    8000281e:	9782                	jalr	a5
}
    80002820:	60a2                	ld	ra,8(sp)
    80002822:	6402                	ld	s0,0(sp)
    80002824:	0141                	addi	sp,sp,16
    80002826:	8082                	ret

0000000080002828 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002828:	1141                	addi	sp,sp,-16
    8000282a:	e406                	sd	ra,8(sp)
    8000282c:	e022                	sd	s0,0(sp)
    8000282e:	0800                	addi	s0,sp,16
  acquire(&tickslock);
    80002830:	00014517          	auipc	a0,0x14
    80002834:	58050513          	addi	a0,a0,1408 # 80016db0 <tickslock>
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	3b2080e7          	jalr	946(ra) # 80000bea <acquire>
  ticks++;
    80002840:	00006717          	auipc	a4,0x6
    80002844:	0d070713          	addi	a4,a4,208 # 80008910 <ticks>
    80002848:	431c                	lw	a5,0(a4)
    8000284a:	2785                	addiw	a5,a5,1
    8000284c:	c31c                	sw	a5,0(a4)

  struct proc *p = myproc();
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	178080e7          	jalr	376(ra) # 800019c6 <myproc>
  if(p && p->state == RUNNING){
    80002856:	c509                	beqz	a0,80002860 <clockintr+0x38>
    80002858:	4d18                	lw	a4,24(a0)
    8000285a:	4791                	li	a5,4
    8000285c:	02f70663          	beq	a4,a5,80002888 <clockintr+0x60>
    p->ticks++;
  }


  wakeup(&ticks);
    80002860:	00006517          	auipc	a0,0x6
    80002864:	0b050513          	addi	a0,a0,176 # 80008910 <ticks>
    80002868:	00000097          	auipc	ra,0x0
    8000286c:	8e8080e7          	jalr	-1816(ra) # 80002150 <wakeup>
  release(&tickslock);
    80002870:	00014517          	auipc	a0,0x14
    80002874:	54050513          	addi	a0,a0,1344 # 80016db0 <tickslock>
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	426080e7          	jalr	1062(ra) # 80000c9e <release>
}
    80002880:	60a2                	ld	ra,8(sp)
    80002882:	6402                	ld	s0,0(sp)
    80002884:	0141                	addi	sp,sp,16
    80002886:	8082                	ret
    p->ticks++;
    80002888:	5d1c                	lw	a5,56(a0)
    8000288a:	2785                	addiw	a5,a5,1
    8000288c:	dd1c                	sw	a5,56(a0)
    8000288e:	bfc9                	j	80002860 <clockintr+0x38>

0000000080002890 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002890:	1101                	addi	sp,sp,-32
    80002892:	ec06                	sd	ra,24(sp)
    80002894:	e822                	sd	s0,16(sp)
    80002896:	e426                	sd	s1,8(sp)
    80002898:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000289a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000289e:	00074d63          	bltz	a4,800028b8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028a2:	57fd                	li	a5,-1
    800028a4:	17fe                	slli	a5,a5,0x3f
    800028a6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028a8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028aa:	06f70363          	beq	a4,a5,80002910 <devintr+0x80>
  }
}
    800028ae:	60e2                	ld	ra,24(sp)
    800028b0:	6442                	ld	s0,16(sp)
    800028b2:	64a2                	ld	s1,8(sp)
    800028b4:	6105                	addi	sp,sp,32
    800028b6:	8082                	ret
     (scause & 0xff) == 9){
    800028b8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028bc:	46a5                	li	a3,9
    800028be:	fed792e3          	bne	a5,a3,800028a2 <devintr+0x12>
    int irq = plic_claim();
    800028c2:	00003097          	auipc	ra,0x3
    800028c6:	4d6080e7          	jalr	1238(ra) # 80005d98 <plic_claim>
    800028ca:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028cc:	47a9                	li	a5,10
    800028ce:	02f50763          	beq	a0,a5,800028fc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028d2:	4785                	li	a5,1
    800028d4:	02f50963          	beq	a0,a5,80002906 <devintr+0x76>
    return 1;
    800028d8:	4505                	li	a0,1
    } else if(irq){
    800028da:	d8f1                	beqz	s1,800028ae <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028dc:	85a6                	mv	a1,s1
    800028de:	00006517          	auipc	a0,0x6
    800028e2:	a4250513          	addi	a0,a0,-1470 # 80008320 <states.1732+0x38>
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	ca8080e7          	jalr	-856(ra) # 8000058e <printf>
      plic_complete(irq);
    800028ee:	8526                	mv	a0,s1
    800028f0:	00003097          	auipc	ra,0x3
    800028f4:	4cc080e7          	jalr	1228(ra) # 80005dbc <plic_complete>
    return 1;
    800028f8:	4505                	li	a0,1
    800028fa:	bf55                	j	800028ae <devintr+0x1e>
      uartintr();
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	0b2080e7          	jalr	178(ra) # 800009ae <uartintr>
    80002904:	b7ed                	j	800028ee <devintr+0x5e>
      virtio_disk_intr();
    80002906:	00004097          	auipc	ra,0x4
    8000290a:	9e0080e7          	jalr	-1568(ra) # 800062e6 <virtio_disk_intr>
    8000290e:	b7c5                	j	800028ee <devintr+0x5e>
    if(cpuid() == 0){
    80002910:	fffff097          	auipc	ra,0xfffff
    80002914:	08a080e7          	jalr	138(ra) # 8000199a <cpuid>
    80002918:	c901                	beqz	a0,80002928 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000291a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000291e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002920:	14479073          	csrw	sip,a5
    return 2;
    80002924:	4509                	li	a0,2
    80002926:	b761                	j	800028ae <devintr+0x1e>
      clockintr();
    80002928:	00000097          	auipc	ra,0x0
    8000292c:	f00080e7          	jalr	-256(ra) # 80002828 <clockintr>
    80002930:	b7ed                	j	8000291a <devintr+0x8a>

0000000080002932 <usertrap>:
{
    80002932:	1101                	addi	sp,sp,-32
    80002934:	ec06                	sd	ra,24(sp)
    80002936:	e822                	sd	s0,16(sp)
    80002938:	e426                	sd	s1,8(sp)
    8000293a:	e04a                	sd	s2,0(sp)
    8000293c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002942:	1007f793          	andi	a5,a5,256
    80002946:	e3b1                	bnez	a5,8000298a <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002948:	00003797          	auipc	a5,0x3
    8000294c:	34878793          	addi	a5,a5,840 # 80005c90 <kernelvec>
    80002950:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002954:	fffff097          	auipc	ra,0xfffff
    80002958:	072080e7          	jalr	114(ra) # 800019c6 <myproc>
    8000295c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000295e:	753c                	ld	a5,104(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002960:	14102773          	csrr	a4,sepc
    80002964:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002966:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000296a:	47a1                	li	a5,8
    8000296c:	02f70763          	beq	a4,a5,8000299a <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002970:	00000097          	auipc	ra,0x0
    80002974:	f20080e7          	jalr	-224(ra) # 80002890 <devintr>
    80002978:	892a                	mv	s2,a0
    8000297a:	c151                	beqz	a0,800029fe <usertrap+0xcc>
  if(killed(p))
    8000297c:	8526                	mv	a0,s1
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	a16080e7          	jalr	-1514(ra) # 80002394 <killed>
    80002986:	c929                	beqz	a0,800029d8 <usertrap+0xa6>
    80002988:	a099                	j	800029ce <usertrap+0x9c>
    panic("usertrap: not from user mode");
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	9b650513          	addi	a0,a0,-1610 # 80008340 <states.1732+0x58>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bb2080e7          	jalr	-1102(ra) # 80000544 <panic>
    if(killed(p))
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	9fa080e7          	jalr	-1542(ra) # 80002394 <killed>
    800029a2:	e921                	bnez	a0,800029f2 <usertrap+0xc0>
    p->trapframe->epc += 4;
    800029a4:	74b8                	ld	a4,104(s1)
    800029a6:	6f1c                	ld	a5,24(a4)
    800029a8:	0791                	addi	a5,a5,4
    800029aa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029b0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b4:	10079073          	csrw	sstatus,a5
    syscall();
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	2d4080e7          	jalr	724(ra) # 80002c8c <syscall>
  if(killed(p))
    800029c0:	8526                	mv	a0,s1
    800029c2:	00000097          	auipc	ra,0x0
    800029c6:	9d2080e7          	jalr	-1582(ra) # 80002394 <killed>
    800029ca:	c911                	beqz	a0,800029de <usertrap+0xac>
    800029cc:	4901                	li	s2,0
    exit(-1);
    800029ce:	557d                	li	a0,-1
    800029d0:	00000097          	auipc	ra,0x0
    800029d4:	850080e7          	jalr	-1968(ra) # 80002220 <exit>
  if(which_dev == 2)
    800029d8:	4789                	li	a5,2
    800029da:	04f90f63          	beq	s2,a5,80002a38 <usertrap+0x106>
  usertrapret();
    800029de:	00000097          	auipc	ra,0x0
    800029e2:	db4080e7          	jalr	-588(ra) # 80002792 <usertrapret>
}
    800029e6:	60e2                	ld	ra,24(sp)
    800029e8:	6442                	ld	s0,16(sp)
    800029ea:	64a2                	ld	s1,8(sp)
    800029ec:	6902                	ld	s2,0(sp)
    800029ee:	6105                	addi	sp,sp,32
    800029f0:	8082                	ret
      exit(-1);
    800029f2:	557d                	li	a0,-1
    800029f4:	00000097          	auipc	ra,0x0
    800029f8:	82c080e7          	jalr	-2004(ra) # 80002220 <exit>
    800029fc:	b765                	j	800029a4 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a02:	5890                	lw	a2,48(s1)
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	95c50513          	addi	a0,a0,-1700 # 80008360 <states.1732+0x78>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	b82080e7          	jalr	-1150(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a14:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a18:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	97450513          	addi	a0,a0,-1676 # 80008390 <states.1732+0xa8>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b6a080e7          	jalr	-1174(ra) # 8000058e <printf>
    setkilled(p);
    80002a2c:	8526                	mv	a0,s1
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	93a080e7          	jalr	-1734(ra) # 80002368 <setkilled>
    80002a36:	b769                	j	800029c0 <usertrap+0x8e>
    yield();
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	678080e7          	jalr	1656(ra) # 800020b0 <yield>
    80002a40:	bf79                	j	800029de <usertrap+0xac>

0000000080002a42 <kerneltrap>:
{
    80002a42:	7179                	addi	sp,sp,-48
    80002a44:	f406                	sd	ra,40(sp)
    80002a46:	f022                	sd	s0,32(sp)
    80002a48:	ec26                	sd	s1,24(sp)
    80002a4a:	e84a                	sd	s2,16(sp)
    80002a4c:	e44e                	sd	s3,8(sp)
    80002a4e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a50:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a54:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a58:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a5c:	1004f793          	andi	a5,s1,256
    80002a60:	cb85                	beqz	a5,80002a90 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a66:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a68:	ef85                	bnez	a5,80002aa0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a6a:	00000097          	auipc	ra,0x0
    80002a6e:	e26080e7          	jalr	-474(ra) # 80002890 <devintr>
    80002a72:	cd1d                	beqz	a0,80002ab0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a74:	4789                	li	a5,2
    80002a76:	06f50a63          	beq	a0,a5,80002aea <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a7a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a7e:	10049073          	csrw	sstatus,s1
}
    80002a82:	70a2                	ld	ra,40(sp)
    80002a84:	7402                	ld	s0,32(sp)
    80002a86:	64e2                	ld	s1,24(sp)
    80002a88:	6942                	ld	s2,16(sp)
    80002a8a:	69a2                	ld	s3,8(sp)
    80002a8c:	6145                	addi	sp,sp,48
    80002a8e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	92050513          	addi	a0,a0,-1760 # 800083b0 <states.1732+0xc8>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	aac080e7          	jalr	-1364(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	93850513          	addi	a0,a0,-1736 # 800083d8 <states.1732+0xf0>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	a9c080e7          	jalr	-1380(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002ab0:	85ce                	mv	a1,s3
    80002ab2:	00006517          	auipc	a0,0x6
    80002ab6:	94650513          	addi	a0,a0,-1722 # 800083f8 <states.1732+0x110>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	ad4080e7          	jalr	-1324(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ac6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aca:	00006517          	auipc	a0,0x6
    80002ace:	93e50513          	addi	a0,a0,-1730 # 80008408 <states.1732+0x120>
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	abc080e7          	jalr	-1348(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002ada:	00006517          	auipc	a0,0x6
    80002ade:	94650513          	addi	a0,a0,-1722 # 80008420 <states.1732+0x138>
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	a62080e7          	jalr	-1438(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aea:	fffff097          	auipc	ra,0xfffff
    80002aee:	edc080e7          	jalr	-292(ra) # 800019c6 <myproc>
    80002af2:	d541                	beqz	a0,80002a7a <kerneltrap+0x38>
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	ed2080e7          	jalr	-302(ra) # 800019c6 <myproc>
    80002afc:	4d18                	lw	a4,24(a0)
    80002afe:	4791                	li	a5,4
    80002b00:	f6f71de3          	bne	a4,a5,80002a7a <kerneltrap+0x38>
    yield();
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	5ac080e7          	jalr	1452(ra) # 800020b0 <yield>
    80002b0c:	b7bd                	j	80002a7a <kerneltrap+0x38>

0000000080002b0e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b0e:	1101                	addi	sp,sp,-32
    80002b10:	ec06                	sd	ra,24(sp)
    80002b12:	e822                	sd	s0,16(sp)
    80002b14:	e426                	sd	s1,8(sp)
    80002b16:	1000                	addi	s0,sp,32
    80002b18:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b1a:	fffff097          	auipc	ra,0xfffff
    80002b1e:	eac080e7          	jalr	-340(ra) # 800019c6 <myproc>
  switch (n) {
    80002b22:	4795                	li	a5,5
    80002b24:	0497e163          	bltu	a5,s1,80002b66 <argraw+0x58>
    80002b28:	048a                	slli	s1,s1,0x2
    80002b2a:	00006717          	auipc	a4,0x6
    80002b2e:	92e70713          	addi	a4,a4,-1746 # 80008458 <states.1732+0x170>
    80002b32:	94ba                	add	s1,s1,a4
    80002b34:	409c                	lw	a5,0(s1)
    80002b36:	97ba                	add	a5,a5,a4
    80002b38:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b3a:	753c                	ld	a5,104(a0)
    80002b3c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b3e:	60e2                	ld	ra,24(sp)
    80002b40:	6442                	ld	s0,16(sp)
    80002b42:	64a2                	ld	s1,8(sp)
    80002b44:	6105                	addi	sp,sp,32
    80002b46:	8082                	ret
    return p->trapframe->a1;
    80002b48:	753c                	ld	a5,104(a0)
    80002b4a:	7fa8                	ld	a0,120(a5)
    80002b4c:	bfcd                	j	80002b3e <argraw+0x30>
    return p->trapframe->a2;
    80002b4e:	753c                	ld	a5,104(a0)
    80002b50:	63c8                	ld	a0,128(a5)
    80002b52:	b7f5                	j	80002b3e <argraw+0x30>
    return p->trapframe->a3;
    80002b54:	753c                	ld	a5,104(a0)
    80002b56:	67c8                	ld	a0,136(a5)
    80002b58:	b7dd                	j	80002b3e <argraw+0x30>
    return p->trapframe->a4;
    80002b5a:	753c                	ld	a5,104(a0)
    80002b5c:	6bc8                	ld	a0,144(a5)
    80002b5e:	b7c5                	j	80002b3e <argraw+0x30>
    return p->trapframe->a5;
    80002b60:	753c                	ld	a5,104(a0)
    80002b62:	6fc8                	ld	a0,152(a5)
    80002b64:	bfe9                	j	80002b3e <argraw+0x30>
  panic("argraw");
    80002b66:	00006517          	auipc	a0,0x6
    80002b6a:	8ca50513          	addi	a0,a0,-1846 # 80008430 <states.1732+0x148>
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	9d6080e7          	jalr	-1578(ra) # 80000544 <panic>

0000000080002b76 <fetchaddr>:
{
    80002b76:	1101                	addi	sp,sp,-32
    80002b78:	ec06                	sd	ra,24(sp)
    80002b7a:	e822                	sd	s0,16(sp)
    80002b7c:	e426                	sd	s1,8(sp)
    80002b7e:	e04a                	sd	s2,0(sp)
    80002b80:	1000                	addi	s0,sp,32
    80002b82:	84aa                	mv	s1,a0
    80002b84:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	e40080e7          	jalr	-448(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b8e:	6d3c                	ld	a5,88(a0)
    80002b90:	02f4f863          	bgeu	s1,a5,80002bc0 <fetchaddr+0x4a>
    80002b94:	00848713          	addi	a4,s1,8
    80002b98:	02e7e663          	bltu	a5,a4,80002bc4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b9c:	46a1                	li	a3,8
    80002b9e:	8626                	mv	a2,s1
    80002ba0:	85ca                	mv	a1,s2
    80002ba2:	7128                	ld	a0,96(a0)
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	b6c080e7          	jalr	-1172(ra) # 80001710 <copyin>
    80002bac:	00a03533          	snez	a0,a0
    80002bb0:	40a00533          	neg	a0,a0
}
    80002bb4:	60e2                	ld	ra,24(sp)
    80002bb6:	6442                	ld	s0,16(sp)
    80002bb8:	64a2                	ld	s1,8(sp)
    80002bba:	6902                	ld	s2,0(sp)
    80002bbc:	6105                	addi	sp,sp,32
    80002bbe:	8082                	ret
    return -1;
    80002bc0:	557d                	li	a0,-1
    80002bc2:	bfcd                	j	80002bb4 <fetchaddr+0x3e>
    80002bc4:	557d                	li	a0,-1
    80002bc6:	b7fd                	j	80002bb4 <fetchaddr+0x3e>

0000000080002bc8 <fetchstr>:
{
    80002bc8:	7179                	addi	sp,sp,-48
    80002bca:	f406                	sd	ra,40(sp)
    80002bcc:	f022                	sd	s0,32(sp)
    80002bce:	ec26                	sd	s1,24(sp)
    80002bd0:	e84a                	sd	s2,16(sp)
    80002bd2:	e44e                	sd	s3,8(sp)
    80002bd4:	1800                	addi	s0,sp,48
    80002bd6:	892a                	mv	s2,a0
    80002bd8:	84ae                	mv	s1,a1
    80002bda:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	dea080e7          	jalr	-534(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002be4:	86ce                	mv	a3,s3
    80002be6:	864a                	mv	a2,s2
    80002be8:	85a6                	mv	a1,s1
    80002bea:	7128                	ld	a0,96(a0)
    80002bec:	fffff097          	auipc	ra,0xfffff
    80002bf0:	bb0080e7          	jalr	-1104(ra) # 8000179c <copyinstr>
    80002bf4:	00054e63          	bltz	a0,80002c10 <fetchstr+0x48>
  return strlen(buf);
    80002bf8:	8526                	mv	a0,s1
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	270080e7          	jalr	624(ra) # 80000e6a <strlen>
}
    80002c02:	70a2                	ld	ra,40(sp)
    80002c04:	7402                	ld	s0,32(sp)
    80002c06:	64e2                	ld	s1,24(sp)
    80002c08:	6942                	ld	s2,16(sp)
    80002c0a:	69a2                	ld	s3,8(sp)
    80002c0c:	6145                	addi	sp,sp,48
    80002c0e:	8082                	ret
    return -1;
    80002c10:	557d                	li	a0,-1
    80002c12:	bfc5                	j	80002c02 <fetchstr+0x3a>

0000000080002c14 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c14:	1101                	addi	sp,sp,-32
    80002c16:	ec06                	sd	ra,24(sp)
    80002c18:	e822                	sd	s0,16(sp)
    80002c1a:	e426                	sd	s1,8(sp)
    80002c1c:	1000                	addi	s0,sp,32
    80002c1e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	eee080e7          	jalr	-274(ra) # 80002b0e <argraw>
    80002c28:	c088                	sw	a0,0(s1)
}
    80002c2a:	60e2                	ld	ra,24(sp)
    80002c2c:	6442                	ld	s0,16(sp)
    80002c2e:	64a2                	ld	s1,8(sp)
    80002c30:	6105                	addi	sp,sp,32
    80002c32:	8082                	ret

0000000080002c34 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c34:	1101                	addi	sp,sp,-32
    80002c36:	ec06                	sd	ra,24(sp)
    80002c38:	e822                	sd	s0,16(sp)
    80002c3a:	e426                	sd	s1,8(sp)
    80002c3c:	1000                	addi	s0,sp,32
    80002c3e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c40:	00000097          	auipc	ra,0x0
    80002c44:	ece080e7          	jalr	-306(ra) # 80002b0e <argraw>
    80002c48:	e088                	sd	a0,0(s1)
}
    80002c4a:	60e2                	ld	ra,24(sp)
    80002c4c:	6442                	ld	s0,16(sp)
    80002c4e:	64a2                	ld	s1,8(sp)
    80002c50:	6105                	addi	sp,sp,32
    80002c52:	8082                	ret

0000000080002c54 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c54:	7179                	addi	sp,sp,-48
    80002c56:	f406                	sd	ra,40(sp)
    80002c58:	f022                	sd	s0,32(sp)
    80002c5a:	ec26                	sd	s1,24(sp)
    80002c5c:	e84a                	sd	s2,16(sp)
    80002c5e:	1800                	addi	s0,sp,48
    80002c60:	84ae                	mv	s1,a1
    80002c62:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c64:	fd840593          	addi	a1,s0,-40
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	fcc080e7          	jalr	-52(ra) # 80002c34 <argaddr>
  return fetchstr(addr, buf, max);
    80002c70:	864a                	mv	a2,s2
    80002c72:	85a6                	mv	a1,s1
    80002c74:	fd843503          	ld	a0,-40(s0)
    80002c78:	00000097          	auipc	ra,0x0
    80002c7c:	f50080e7          	jalr	-176(ra) # 80002bc8 <fetchstr>
}
    80002c80:	70a2                	ld	ra,40(sp)
    80002c82:	7402                	ld	s0,32(sp)
    80002c84:	64e2                	ld	s1,24(sp)
    80002c86:	6942                	ld	s2,16(sp)
    80002c88:	6145                	addi	sp,sp,48
    80002c8a:	8082                	ret

0000000080002c8c <syscall>:
[SYS_sched_tickets] sys_sched_tickets,
};

void
syscall(void)
{
    80002c8c:	1101                	addi	sp,sp,-32
    80002c8e:	ec06                	sd	ra,24(sp)
    80002c90:	e822                	sd	s0,16(sp)
    80002c92:	e426                	sd	s1,8(sp)
    80002c94:	e04a                	sd	s2,0(sp)
    80002c96:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	d2e080e7          	jalr	-722(ra) # 800019c6 <myproc>
    80002ca0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ca2:	06853903          	ld	s2,104(a0)
    80002ca6:	0a893783          	ld	a5,168(s2)
    80002caa:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cae:	37fd                	addiw	a5,a5,-1
    80002cb0:	4759                	li	a4,22
    80002cb2:	00f76f63          	bltu	a4,a5,80002cd0 <syscall+0x44>
    80002cb6:	00369713          	slli	a4,a3,0x3
    80002cba:	00005797          	auipc	a5,0x5
    80002cbe:	7b678793          	addi	a5,a5,1974 # 80008470 <syscalls>
    80002cc2:	97ba                	add	a5,a5,a4
    80002cc4:	639c                	ld	a5,0(a5)
    80002cc6:	c789                	beqz	a5,80002cd0 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002cc8:	9782                	jalr	a5
    80002cca:	06a93823          	sd	a0,112(s2)
    80002cce:	a839                	j	80002cec <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cd0:	16848613          	addi	a2,s1,360
    80002cd4:	588c                	lw	a1,48(s1)
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	76250513          	addi	a0,a0,1890 # 80008438 <states.1732+0x150>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	8b0080e7          	jalr	-1872(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ce6:	74bc                	ld	a5,104(s1)
    80002ce8:	577d                	li	a4,-1
    80002cea:	fbb8                	sd	a4,112(a5)
  }
}
    80002cec:	60e2                	ld	ra,24(sp)
    80002cee:	6442                	ld	s0,16(sp)
    80002cf0:	64a2                	ld	s1,8(sp)
    80002cf2:	6902                	ld	s2,0(sp)
    80002cf4:	6105                	addi	sp,sp,32
    80002cf6:	8082                	ret

0000000080002cf8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cf8:	1101                	addi	sp,sp,-32
    80002cfa:	ec06                	sd	ra,24(sp)
    80002cfc:	e822                	sd	s0,16(sp)
    80002cfe:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d00:	fec40593          	addi	a1,s0,-20
    80002d04:	4501                	li	a0,0
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	f0e080e7          	jalr	-242(ra) # 80002c14 <argint>
  exit(n);
    80002d0e:	fec42503          	lw	a0,-20(s0)
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	50e080e7          	jalr	1294(ra) # 80002220 <exit>
  return 0;  // not reached
}
    80002d1a:	4501                	li	a0,0
    80002d1c:	60e2                	ld	ra,24(sp)
    80002d1e:	6442                	ld	s0,16(sp)
    80002d20:	6105                	addi	sp,sp,32
    80002d22:	8082                	ret

0000000080002d24 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d24:	1141                	addi	sp,sp,-16
    80002d26:	e406                	sd	ra,8(sp)
    80002d28:	e022                	sd	s0,0(sp)
    80002d2a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	c9a080e7          	jalr	-870(ra) # 800019c6 <myproc>
}
    80002d34:	5908                	lw	a0,48(a0)
    80002d36:	60a2                	ld	ra,8(sp)
    80002d38:	6402                	ld	s0,0(sp)
    80002d3a:	0141                	addi	sp,sp,16
    80002d3c:	8082                	ret

0000000080002d3e <sys_fork>:

uint64
sys_fork(void)
{
    80002d3e:	1141                	addi	sp,sp,-16
    80002d40:	e406                	sd	ra,8(sp)
    80002d42:	e022                	sd	s0,0(sp)
    80002d44:	0800                	addi	s0,sp,16
  return fork();
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	04a080e7          	jalr	74(ra) # 80001d90 <fork>
}
    80002d4e:	60a2                	ld	ra,8(sp)
    80002d50:	6402                	ld	s0,0(sp)
    80002d52:	0141                	addi	sp,sp,16
    80002d54:	8082                	ret

0000000080002d56 <sys_wait>:

uint64
sys_wait(void)
{
    80002d56:	1101                	addi	sp,sp,-32
    80002d58:	ec06                	sd	ra,24(sp)
    80002d5a:	e822                	sd	s0,16(sp)
    80002d5c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d5e:	fe840593          	addi	a1,s0,-24
    80002d62:	4501                	li	a0,0
    80002d64:	00000097          	auipc	ra,0x0
    80002d68:	ed0080e7          	jalr	-304(ra) # 80002c34 <argaddr>
  return wait(p);
    80002d6c:	fe843503          	ld	a0,-24(s0)
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	656080e7          	jalr	1622(ra) # 800023c6 <wait>
}
    80002d78:	60e2                	ld	ra,24(sp)
    80002d7a:	6442                	ld	s0,16(sp)
    80002d7c:	6105                	addi	sp,sp,32
    80002d7e:	8082                	ret

0000000080002d80 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d80:	7179                	addi	sp,sp,-48
    80002d82:	f406                	sd	ra,40(sp)
    80002d84:	f022                	sd	s0,32(sp)
    80002d86:	ec26                	sd	s1,24(sp)
    80002d88:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d8a:	fdc40593          	addi	a1,s0,-36
    80002d8e:	4501                	li	a0,0
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	e84080e7          	jalr	-380(ra) # 80002c14 <argint>
  addr = myproc()->sz;
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	c2e080e7          	jalr	-978(ra) # 800019c6 <myproc>
    80002da0:	6d24                	ld	s1,88(a0)
  if(growproc(n) < 0)
    80002da2:	fdc42503          	lw	a0,-36(s0)
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	f8e080e7          	jalr	-114(ra) # 80001d34 <growproc>
    80002dae:	00054863          	bltz	a0,80002dbe <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002db2:	8526                	mv	a0,s1
    80002db4:	70a2                	ld	ra,40(sp)
    80002db6:	7402                	ld	s0,32(sp)
    80002db8:	64e2                	ld	s1,24(sp)
    80002dba:	6145                	addi	sp,sp,48
    80002dbc:	8082                	ret
    return -1;
    80002dbe:	54fd                	li	s1,-1
    80002dc0:	bfcd                	j	80002db2 <sys_sbrk+0x32>

0000000080002dc2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dc2:	7139                	addi	sp,sp,-64
    80002dc4:	fc06                	sd	ra,56(sp)
    80002dc6:	f822                	sd	s0,48(sp)
    80002dc8:	f426                	sd	s1,40(sp)
    80002dca:	f04a                	sd	s2,32(sp)
    80002dcc:	ec4e                	sd	s3,24(sp)
    80002dce:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002dd0:	fcc40593          	addi	a1,s0,-52
    80002dd4:	4501                	li	a0,0
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	e3e080e7          	jalr	-450(ra) # 80002c14 <argint>
  acquire(&tickslock);
    80002dde:	00014517          	auipc	a0,0x14
    80002de2:	fd250513          	addi	a0,a0,-46 # 80016db0 <tickslock>
    80002de6:	ffffe097          	auipc	ra,0xffffe
    80002dea:	e04080e7          	jalr	-508(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002dee:	00006917          	auipc	s2,0x6
    80002df2:	b2292903          	lw	s2,-1246(s2) # 80008910 <ticks>
  while(ticks - ticks0 < n){
    80002df6:	fcc42783          	lw	a5,-52(s0)
    80002dfa:	cf9d                	beqz	a5,80002e38 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dfc:	00014997          	auipc	s3,0x14
    80002e00:	fb498993          	addi	s3,s3,-76 # 80016db0 <tickslock>
    80002e04:	00006497          	auipc	s1,0x6
    80002e08:	b0c48493          	addi	s1,s1,-1268 # 80008910 <ticks>
    if(killed(myproc())){
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	bba080e7          	jalr	-1094(ra) # 800019c6 <myproc>
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	580080e7          	jalr	1408(ra) # 80002394 <killed>
    80002e1c:	ed15                	bnez	a0,80002e58 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e1e:	85ce                	mv	a1,s3
    80002e20:	8526                	mv	a0,s1
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	2ca080e7          	jalr	714(ra) # 800020ec <sleep>
  while(ticks - ticks0 < n){
    80002e2a:	409c                	lw	a5,0(s1)
    80002e2c:	412787bb          	subw	a5,a5,s2
    80002e30:	fcc42703          	lw	a4,-52(s0)
    80002e34:	fce7ece3          	bltu	a5,a4,80002e0c <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e38:	00014517          	auipc	a0,0x14
    80002e3c:	f7850513          	addi	a0,a0,-136 # 80016db0 <tickslock>
    80002e40:	ffffe097          	auipc	ra,0xffffe
    80002e44:	e5e080e7          	jalr	-418(ra) # 80000c9e <release>
  return 0;
    80002e48:	4501                	li	a0,0
}
    80002e4a:	70e2                	ld	ra,56(sp)
    80002e4c:	7442                	ld	s0,48(sp)
    80002e4e:	74a2                	ld	s1,40(sp)
    80002e50:	7902                	ld	s2,32(sp)
    80002e52:	69e2                	ld	s3,24(sp)
    80002e54:	6121                	addi	sp,sp,64
    80002e56:	8082                	ret
      release(&tickslock);
    80002e58:	00014517          	auipc	a0,0x14
    80002e5c:	f5850513          	addi	a0,a0,-168 # 80016db0 <tickslock>
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	e3e080e7          	jalr	-450(ra) # 80000c9e <release>
      return -1;
    80002e68:	557d                	li	a0,-1
    80002e6a:	b7c5                	j	80002e4a <sys_sleep+0x88>

0000000080002e6c <sys_kill>:

uint64
sys_kill(void)
{
    80002e6c:	1101                	addi	sp,sp,-32
    80002e6e:	ec06                	sd	ra,24(sp)
    80002e70:	e822                	sd	s0,16(sp)
    80002e72:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e74:	fec40593          	addi	a1,s0,-20
    80002e78:	4501                	li	a0,0
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	d9a080e7          	jalr	-614(ra) # 80002c14 <argint>
  return kill(pid);
    80002e82:	fec42503          	lw	a0,-20(s0)
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	470080e7          	jalr	1136(ra) # 800022f6 <kill>
}
    80002e8e:	60e2                	ld	ra,24(sp)
    80002e90:	6442                	ld	s0,16(sp)
    80002e92:	6105                	addi	sp,sp,32
    80002e94:	8082                	ret

0000000080002e96 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e96:	1101                	addi	sp,sp,-32
    80002e98:	ec06                	sd	ra,24(sp)
    80002e9a:	e822                	sd	s0,16(sp)
    80002e9c:	e426                	sd	s1,8(sp)
    80002e9e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ea0:	00014517          	auipc	a0,0x14
    80002ea4:	f1050513          	addi	a0,a0,-240 # 80016db0 <tickslock>
    80002ea8:	ffffe097          	auipc	ra,0xffffe
    80002eac:	d42080e7          	jalr	-702(ra) # 80000bea <acquire>
  xticks = ticks;
    80002eb0:	00006497          	auipc	s1,0x6
    80002eb4:	a604a483          	lw	s1,-1440(s1) # 80008910 <ticks>
  release(&tickslock);
    80002eb8:	00014517          	auipc	a0,0x14
    80002ebc:	ef850513          	addi	a0,a0,-264 # 80016db0 <tickslock>
    80002ec0:	ffffe097          	auipc	ra,0xffffe
    80002ec4:	dde080e7          	jalr	-546(ra) # 80000c9e <release>
  return xticks;
}
    80002ec8:	02049513          	slli	a0,s1,0x20
    80002ecc:	9101                	srli	a0,a0,0x20
    80002ece:	60e2                	ld	ra,24(sp)
    80002ed0:	6442                	ld	s0,16(sp)
    80002ed2:	64a2                	ld	s1,8(sp)
    80002ed4:	6105                	addi	sp,sp,32
    80002ed6:	8082                	ret

0000000080002ed8 <sys_sched_statistics>:

uint64
sys_sched_statistics(void)
{
    80002ed8:	1141                	addi	sp,sp,-16
    80002eda:	e406                	sd	ra,8(sp)
    80002edc:	e022                	sd	s0,0(sp)
    80002ede:	0800                	addi	s0,sp,16
  return sched_statistics();
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	76e080e7          	jalr	1902(ra) # 8000264e <sched_statistics>
}
    80002ee8:	60a2                	ld	ra,8(sp)
    80002eea:	6402                	ld	s0,0(sp)
    80002eec:	0141                	addi	sp,sp,16
    80002eee:	8082                	ret

0000000080002ef0 <sys_sched_tickets>:

uint64
sys_sched_tickets(void)
{
    80002ef0:	1101                	addi	sp,sp,-32
    80002ef2:	ec06                	sd	ra,24(sp)
    80002ef4:	e822                	sd	s0,16(sp)
    80002ef6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ef8:	fec40593          	addi	a1,s0,-20
    80002efc:	4501                	li	a0,0
    80002efe:	00000097          	auipc	ra,0x0
    80002f02:	d16080e7          	jalr	-746(ra) # 80002c14 <argint>
  return sched_tickets(n);
    80002f06:	fec42503          	lw	a0,-20(s0)
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	79e080e7          	jalr	1950(ra) # 800026a8 <sched_tickets>
}
    80002f12:	60e2                	ld	ra,24(sp)
    80002f14:	6442                	ld	s0,16(sp)
    80002f16:	6105                	addi	sp,sp,32
    80002f18:	8082                	ret

0000000080002f1a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f1a:	7179                	addi	sp,sp,-48
    80002f1c:	f406                	sd	ra,40(sp)
    80002f1e:	f022                	sd	s0,32(sp)
    80002f20:	ec26                	sd	s1,24(sp)
    80002f22:	e84a                	sd	s2,16(sp)
    80002f24:	e44e                	sd	s3,8(sp)
    80002f26:	e052                	sd	s4,0(sp)
    80002f28:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f2a:	00005597          	auipc	a1,0x5
    80002f2e:	60658593          	addi	a1,a1,1542 # 80008530 <syscalls+0xc0>
    80002f32:	00014517          	auipc	a0,0x14
    80002f36:	e9650513          	addi	a0,a0,-362 # 80016dc8 <bcache>
    80002f3a:	ffffe097          	auipc	ra,0xffffe
    80002f3e:	c20080e7          	jalr	-992(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f42:	0001c797          	auipc	a5,0x1c
    80002f46:	e8678793          	addi	a5,a5,-378 # 8001edc8 <bcache+0x8000>
    80002f4a:	0001c717          	auipc	a4,0x1c
    80002f4e:	0e670713          	addi	a4,a4,230 # 8001f030 <bcache+0x8268>
    80002f52:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f56:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f5a:	00014497          	auipc	s1,0x14
    80002f5e:	e8648493          	addi	s1,s1,-378 # 80016de0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f62:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f64:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f66:	00005a17          	auipc	s4,0x5
    80002f6a:	5d2a0a13          	addi	s4,s4,1490 # 80008538 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f6e:	2b893783          	ld	a5,696(s2)
    80002f72:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f74:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f78:	85d2                	mv	a1,s4
    80002f7a:	01048513          	addi	a0,s1,16
    80002f7e:	00001097          	auipc	ra,0x1
    80002f82:	4c4080e7          	jalr	1220(ra) # 80004442 <initsleeplock>
    bcache.head.next->prev = b;
    80002f86:	2b893783          	ld	a5,696(s2)
    80002f8a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f8c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f90:	45848493          	addi	s1,s1,1112
    80002f94:	fd349de3          	bne	s1,s3,80002f6e <binit+0x54>
  }
}
    80002f98:	70a2                	ld	ra,40(sp)
    80002f9a:	7402                	ld	s0,32(sp)
    80002f9c:	64e2                	ld	s1,24(sp)
    80002f9e:	6942                	ld	s2,16(sp)
    80002fa0:	69a2                	ld	s3,8(sp)
    80002fa2:	6a02                	ld	s4,0(sp)
    80002fa4:	6145                	addi	sp,sp,48
    80002fa6:	8082                	ret

0000000080002fa8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fa8:	7179                	addi	sp,sp,-48
    80002faa:	f406                	sd	ra,40(sp)
    80002fac:	f022                	sd	s0,32(sp)
    80002fae:	ec26                	sd	s1,24(sp)
    80002fb0:	e84a                	sd	s2,16(sp)
    80002fb2:	e44e                	sd	s3,8(sp)
    80002fb4:	1800                	addi	s0,sp,48
    80002fb6:	89aa                	mv	s3,a0
    80002fb8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fba:	00014517          	auipc	a0,0x14
    80002fbe:	e0e50513          	addi	a0,a0,-498 # 80016dc8 <bcache>
    80002fc2:	ffffe097          	auipc	ra,0xffffe
    80002fc6:	c28080e7          	jalr	-984(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fca:	0001c497          	auipc	s1,0x1c
    80002fce:	0b64b483          	ld	s1,182(s1) # 8001f080 <bcache+0x82b8>
    80002fd2:	0001c797          	auipc	a5,0x1c
    80002fd6:	05e78793          	addi	a5,a5,94 # 8001f030 <bcache+0x8268>
    80002fda:	02f48f63          	beq	s1,a5,80003018 <bread+0x70>
    80002fde:	873e                	mv	a4,a5
    80002fe0:	a021                	j	80002fe8 <bread+0x40>
    80002fe2:	68a4                	ld	s1,80(s1)
    80002fe4:	02e48a63          	beq	s1,a4,80003018 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fe8:	449c                	lw	a5,8(s1)
    80002fea:	ff379ce3          	bne	a5,s3,80002fe2 <bread+0x3a>
    80002fee:	44dc                	lw	a5,12(s1)
    80002ff0:	ff2799e3          	bne	a5,s2,80002fe2 <bread+0x3a>
      b->refcnt++;
    80002ff4:	40bc                	lw	a5,64(s1)
    80002ff6:	2785                	addiw	a5,a5,1
    80002ff8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ffa:	00014517          	auipc	a0,0x14
    80002ffe:	dce50513          	addi	a0,a0,-562 # 80016dc8 <bcache>
    80003002:	ffffe097          	auipc	ra,0xffffe
    80003006:	c9c080e7          	jalr	-868(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000300a:	01048513          	addi	a0,s1,16
    8000300e:	00001097          	auipc	ra,0x1
    80003012:	46e080e7          	jalr	1134(ra) # 8000447c <acquiresleep>
      return b;
    80003016:	a8b9                	j	80003074 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003018:	0001c497          	auipc	s1,0x1c
    8000301c:	0604b483          	ld	s1,96(s1) # 8001f078 <bcache+0x82b0>
    80003020:	0001c797          	auipc	a5,0x1c
    80003024:	01078793          	addi	a5,a5,16 # 8001f030 <bcache+0x8268>
    80003028:	00f48863          	beq	s1,a5,80003038 <bread+0x90>
    8000302c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000302e:	40bc                	lw	a5,64(s1)
    80003030:	cf81                	beqz	a5,80003048 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003032:	64a4                	ld	s1,72(s1)
    80003034:	fee49de3          	bne	s1,a4,8000302e <bread+0x86>
  panic("bget: no buffers");
    80003038:	00005517          	auipc	a0,0x5
    8000303c:	50850513          	addi	a0,a0,1288 # 80008540 <syscalls+0xd0>
    80003040:	ffffd097          	auipc	ra,0xffffd
    80003044:	504080e7          	jalr	1284(ra) # 80000544 <panic>
      b->dev = dev;
    80003048:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000304c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003050:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003054:	4785                	li	a5,1
    80003056:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003058:	00014517          	auipc	a0,0x14
    8000305c:	d7050513          	addi	a0,a0,-656 # 80016dc8 <bcache>
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	c3e080e7          	jalr	-962(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003068:	01048513          	addi	a0,s1,16
    8000306c:	00001097          	auipc	ra,0x1
    80003070:	410080e7          	jalr	1040(ra) # 8000447c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003074:	409c                	lw	a5,0(s1)
    80003076:	cb89                	beqz	a5,80003088 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003078:	8526                	mv	a0,s1
    8000307a:	70a2                	ld	ra,40(sp)
    8000307c:	7402                	ld	s0,32(sp)
    8000307e:	64e2                	ld	s1,24(sp)
    80003080:	6942                	ld	s2,16(sp)
    80003082:	69a2                	ld	s3,8(sp)
    80003084:	6145                	addi	sp,sp,48
    80003086:	8082                	ret
    virtio_disk_rw(b, 0);
    80003088:	4581                	li	a1,0
    8000308a:	8526                	mv	a0,s1
    8000308c:	00003097          	auipc	ra,0x3
    80003090:	fcc080e7          	jalr	-52(ra) # 80006058 <virtio_disk_rw>
    b->valid = 1;
    80003094:	4785                	li	a5,1
    80003096:	c09c                	sw	a5,0(s1)
  return b;
    80003098:	b7c5                	j	80003078 <bread+0xd0>

000000008000309a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000309a:	1101                	addi	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	1000                	addi	s0,sp,32
    800030a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030a6:	0541                	addi	a0,a0,16
    800030a8:	00001097          	auipc	ra,0x1
    800030ac:	46e080e7          	jalr	1134(ra) # 80004516 <holdingsleep>
    800030b0:	cd01                	beqz	a0,800030c8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030b2:	4585                	li	a1,1
    800030b4:	8526                	mv	a0,s1
    800030b6:	00003097          	auipc	ra,0x3
    800030ba:	fa2080e7          	jalr	-94(ra) # 80006058 <virtio_disk_rw>
}
    800030be:	60e2                	ld	ra,24(sp)
    800030c0:	6442                	ld	s0,16(sp)
    800030c2:	64a2                	ld	s1,8(sp)
    800030c4:	6105                	addi	sp,sp,32
    800030c6:	8082                	ret
    panic("bwrite");
    800030c8:	00005517          	auipc	a0,0x5
    800030cc:	49050513          	addi	a0,a0,1168 # 80008558 <syscalls+0xe8>
    800030d0:	ffffd097          	auipc	ra,0xffffd
    800030d4:	474080e7          	jalr	1140(ra) # 80000544 <panic>

00000000800030d8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030d8:	1101                	addi	sp,sp,-32
    800030da:	ec06                	sd	ra,24(sp)
    800030dc:	e822                	sd	s0,16(sp)
    800030de:	e426                	sd	s1,8(sp)
    800030e0:	e04a                	sd	s2,0(sp)
    800030e2:	1000                	addi	s0,sp,32
    800030e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030e6:	01050913          	addi	s2,a0,16
    800030ea:	854a                	mv	a0,s2
    800030ec:	00001097          	auipc	ra,0x1
    800030f0:	42a080e7          	jalr	1066(ra) # 80004516 <holdingsleep>
    800030f4:	c92d                	beqz	a0,80003166 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030f6:	854a                	mv	a0,s2
    800030f8:	00001097          	auipc	ra,0x1
    800030fc:	3da080e7          	jalr	986(ra) # 800044d2 <releasesleep>

  acquire(&bcache.lock);
    80003100:	00014517          	auipc	a0,0x14
    80003104:	cc850513          	addi	a0,a0,-824 # 80016dc8 <bcache>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	ae2080e7          	jalr	-1310(ra) # 80000bea <acquire>
  b->refcnt--;
    80003110:	40bc                	lw	a5,64(s1)
    80003112:	37fd                	addiw	a5,a5,-1
    80003114:	0007871b          	sext.w	a4,a5
    80003118:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000311a:	eb05                	bnez	a4,8000314a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000311c:	68bc                	ld	a5,80(s1)
    8000311e:	64b8                	ld	a4,72(s1)
    80003120:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003122:	64bc                	ld	a5,72(s1)
    80003124:	68b8                	ld	a4,80(s1)
    80003126:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003128:	0001c797          	auipc	a5,0x1c
    8000312c:	ca078793          	addi	a5,a5,-864 # 8001edc8 <bcache+0x8000>
    80003130:	2b87b703          	ld	a4,696(a5)
    80003134:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003136:	0001c717          	auipc	a4,0x1c
    8000313a:	efa70713          	addi	a4,a4,-262 # 8001f030 <bcache+0x8268>
    8000313e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003140:	2b87b703          	ld	a4,696(a5)
    80003144:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003146:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000314a:	00014517          	auipc	a0,0x14
    8000314e:	c7e50513          	addi	a0,a0,-898 # 80016dc8 <bcache>
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	b4c080e7          	jalr	-1204(ra) # 80000c9e <release>
}
    8000315a:	60e2                	ld	ra,24(sp)
    8000315c:	6442                	ld	s0,16(sp)
    8000315e:	64a2                	ld	s1,8(sp)
    80003160:	6902                	ld	s2,0(sp)
    80003162:	6105                	addi	sp,sp,32
    80003164:	8082                	ret
    panic("brelse");
    80003166:	00005517          	auipc	a0,0x5
    8000316a:	3fa50513          	addi	a0,a0,1018 # 80008560 <syscalls+0xf0>
    8000316e:	ffffd097          	auipc	ra,0xffffd
    80003172:	3d6080e7          	jalr	982(ra) # 80000544 <panic>

0000000080003176 <bpin>:

void
bpin(struct buf *b) {
    80003176:	1101                	addi	sp,sp,-32
    80003178:	ec06                	sd	ra,24(sp)
    8000317a:	e822                	sd	s0,16(sp)
    8000317c:	e426                	sd	s1,8(sp)
    8000317e:	1000                	addi	s0,sp,32
    80003180:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003182:	00014517          	auipc	a0,0x14
    80003186:	c4650513          	addi	a0,a0,-954 # 80016dc8 <bcache>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	a60080e7          	jalr	-1440(ra) # 80000bea <acquire>
  b->refcnt++;
    80003192:	40bc                	lw	a5,64(s1)
    80003194:	2785                	addiw	a5,a5,1
    80003196:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003198:	00014517          	auipc	a0,0x14
    8000319c:	c3050513          	addi	a0,a0,-976 # 80016dc8 <bcache>
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	afe080e7          	jalr	-1282(ra) # 80000c9e <release>
}
    800031a8:	60e2                	ld	ra,24(sp)
    800031aa:	6442                	ld	s0,16(sp)
    800031ac:	64a2                	ld	s1,8(sp)
    800031ae:	6105                	addi	sp,sp,32
    800031b0:	8082                	ret

00000000800031b2 <bunpin>:

void
bunpin(struct buf *b) {
    800031b2:	1101                	addi	sp,sp,-32
    800031b4:	ec06                	sd	ra,24(sp)
    800031b6:	e822                	sd	s0,16(sp)
    800031b8:	e426                	sd	s1,8(sp)
    800031ba:	1000                	addi	s0,sp,32
    800031bc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031be:	00014517          	auipc	a0,0x14
    800031c2:	c0a50513          	addi	a0,a0,-1014 # 80016dc8 <bcache>
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	a24080e7          	jalr	-1500(ra) # 80000bea <acquire>
  b->refcnt--;
    800031ce:	40bc                	lw	a5,64(s1)
    800031d0:	37fd                	addiw	a5,a5,-1
    800031d2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031d4:	00014517          	auipc	a0,0x14
    800031d8:	bf450513          	addi	a0,a0,-1036 # 80016dc8 <bcache>
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	ac2080e7          	jalr	-1342(ra) # 80000c9e <release>
}
    800031e4:	60e2                	ld	ra,24(sp)
    800031e6:	6442                	ld	s0,16(sp)
    800031e8:	64a2                	ld	s1,8(sp)
    800031ea:	6105                	addi	sp,sp,32
    800031ec:	8082                	ret

00000000800031ee <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031ee:	1101                	addi	sp,sp,-32
    800031f0:	ec06                	sd	ra,24(sp)
    800031f2:	e822                	sd	s0,16(sp)
    800031f4:	e426                	sd	s1,8(sp)
    800031f6:	e04a                	sd	s2,0(sp)
    800031f8:	1000                	addi	s0,sp,32
    800031fa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031fc:	00d5d59b          	srliw	a1,a1,0xd
    80003200:	0001c797          	auipc	a5,0x1c
    80003204:	2a47a783          	lw	a5,676(a5) # 8001f4a4 <sb+0x1c>
    80003208:	9dbd                	addw	a1,a1,a5
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	d9e080e7          	jalr	-610(ra) # 80002fa8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003212:	0074f713          	andi	a4,s1,7
    80003216:	4785                	li	a5,1
    80003218:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000321c:	14ce                	slli	s1,s1,0x33
    8000321e:	90d9                	srli	s1,s1,0x36
    80003220:	00950733          	add	a4,a0,s1
    80003224:	05874703          	lbu	a4,88(a4)
    80003228:	00e7f6b3          	and	a3,a5,a4
    8000322c:	c69d                	beqz	a3,8000325a <bfree+0x6c>
    8000322e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003230:	94aa                	add	s1,s1,a0
    80003232:	fff7c793          	not	a5,a5
    80003236:	8ff9                	and	a5,a5,a4
    80003238:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000323c:	00001097          	auipc	ra,0x1
    80003240:	120080e7          	jalr	288(ra) # 8000435c <log_write>
  brelse(bp);
    80003244:	854a                	mv	a0,s2
    80003246:	00000097          	auipc	ra,0x0
    8000324a:	e92080e7          	jalr	-366(ra) # 800030d8 <brelse>
}
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	64a2                	ld	s1,8(sp)
    80003254:	6902                	ld	s2,0(sp)
    80003256:	6105                	addi	sp,sp,32
    80003258:	8082                	ret
    panic("freeing free block");
    8000325a:	00005517          	auipc	a0,0x5
    8000325e:	30e50513          	addi	a0,a0,782 # 80008568 <syscalls+0xf8>
    80003262:	ffffd097          	auipc	ra,0xffffd
    80003266:	2e2080e7          	jalr	738(ra) # 80000544 <panic>

000000008000326a <balloc>:
{
    8000326a:	711d                	addi	sp,sp,-96
    8000326c:	ec86                	sd	ra,88(sp)
    8000326e:	e8a2                	sd	s0,80(sp)
    80003270:	e4a6                	sd	s1,72(sp)
    80003272:	e0ca                	sd	s2,64(sp)
    80003274:	fc4e                	sd	s3,56(sp)
    80003276:	f852                	sd	s4,48(sp)
    80003278:	f456                	sd	s5,40(sp)
    8000327a:	f05a                	sd	s6,32(sp)
    8000327c:	ec5e                	sd	s7,24(sp)
    8000327e:	e862                	sd	s8,16(sp)
    80003280:	e466                	sd	s9,8(sp)
    80003282:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003284:	0001c797          	auipc	a5,0x1c
    80003288:	2087a783          	lw	a5,520(a5) # 8001f48c <sb+0x4>
    8000328c:	10078163          	beqz	a5,8000338e <balloc+0x124>
    80003290:	8baa                	mv	s7,a0
    80003292:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003294:	0001cb17          	auipc	s6,0x1c
    80003298:	1f4b0b13          	addi	s6,s6,500 # 8001f488 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000329c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000329e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032a2:	6c89                	lui	s9,0x2
    800032a4:	a061                	j	8000332c <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032a6:	974a                	add	a4,a4,s2
    800032a8:	8fd5                	or	a5,a5,a3
    800032aa:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032ae:	854a                	mv	a0,s2
    800032b0:	00001097          	auipc	ra,0x1
    800032b4:	0ac080e7          	jalr	172(ra) # 8000435c <log_write>
        brelse(bp);
    800032b8:	854a                	mv	a0,s2
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	e1e080e7          	jalr	-482(ra) # 800030d8 <brelse>
  bp = bread(dev, bno);
    800032c2:	85a6                	mv	a1,s1
    800032c4:	855e                	mv	a0,s7
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	ce2080e7          	jalr	-798(ra) # 80002fa8 <bread>
    800032ce:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032d0:	40000613          	li	a2,1024
    800032d4:	4581                	li	a1,0
    800032d6:	05850513          	addi	a0,a0,88
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	a0c080e7          	jalr	-1524(ra) # 80000ce6 <memset>
  log_write(bp);
    800032e2:	854a                	mv	a0,s2
    800032e4:	00001097          	auipc	ra,0x1
    800032e8:	078080e7          	jalr	120(ra) # 8000435c <log_write>
  brelse(bp);
    800032ec:	854a                	mv	a0,s2
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	dea080e7          	jalr	-534(ra) # 800030d8 <brelse>
}
    800032f6:	8526                	mv	a0,s1
    800032f8:	60e6                	ld	ra,88(sp)
    800032fa:	6446                	ld	s0,80(sp)
    800032fc:	64a6                	ld	s1,72(sp)
    800032fe:	6906                	ld	s2,64(sp)
    80003300:	79e2                	ld	s3,56(sp)
    80003302:	7a42                	ld	s4,48(sp)
    80003304:	7aa2                	ld	s5,40(sp)
    80003306:	7b02                	ld	s6,32(sp)
    80003308:	6be2                	ld	s7,24(sp)
    8000330a:	6c42                	ld	s8,16(sp)
    8000330c:	6ca2                	ld	s9,8(sp)
    8000330e:	6125                	addi	sp,sp,96
    80003310:	8082                	ret
    brelse(bp);
    80003312:	854a                	mv	a0,s2
    80003314:	00000097          	auipc	ra,0x0
    80003318:	dc4080e7          	jalr	-572(ra) # 800030d8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000331c:	015c87bb          	addw	a5,s9,s5
    80003320:	00078a9b          	sext.w	s5,a5
    80003324:	004b2703          	lw	a4,4(s6)
    80003328:	06eaf363          	bgeu	s5,a4,8000338e <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000332c:	41fad79b          	sraiw	a5,s5,0x1f
    80003330:	0137d79b          	srliw	a5,a5,0x13
    80003334:	015787bb          	addw	a5,a5,s5
    80003338:	40d7d79b          	sraiw	a5,a5,0xd
    8000333c:	01cb2583          	lw	a1,28(s6)
    80003340:	9dbd                	addw	a1,a1,a5
    80003342:	855e                	mv	a0,s7
    80003344:	00000097          	auipc	ra,0x0
    80003348:	c64080e7          	jalr	-924(ra) # 80002fa8 <bread>
    8000334c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000334e:	004b2503          	lw	a0,4(s6)
    80003352:	000a849b          	sext.w	s1,s5
    80003356:	8662                	mv	a2,s8
    80003358:	faa4fde3          	bgeu	s1,a0,80003312 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000335c:	41f6579b          	sraiw	a5,a2,0x1f
    80003360:	01d7d69b          	srliw	a3,a5,0x1d
    80003364:	00c6873b          	addw	a4,a3,a2
    80003368:	00777793          	andi	a5,a4,7
    8000336c:	9f95                	subw	a5,a5,a3
    8000336e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003372:	4037571b          	sraiw	a4,a4,0x3
    80003376:	00e906b3          	add	a3,s2,a4
    8000337a:	0586c683          	lbu	a3,88(a3)
    8000337e:	00d7f5b3          	and	a1,a5,a3
    80003382:	d195                	beqz	a1,800032a6 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003384:	2605                	addiw	a2,a2,1
    80003386:	2485                	addiw	s1,s1,1
    80003388:	fd4618e3          	bne	a2,s4,80003358 <balloc+0xee>
    8000338c:	b759                	j	80003312 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000338e:	00005517          	auipc	a0,0x5
    80003392:	1f250513          	addi	a0,a0,498 # 80008580 <syscalls+0x110>
    80003396:	ffffd097          	auipc	ra,0xffffd
    8000339a:	1f8080e7          	jalr	504(ra) # 8000058e <printf>
  return 0;
    8000339e:	4481                	li	s1,0
    800033a0:	bf99                	j	800032f6 <balloc+0x8c>

00000000800033a2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033a2:	7179                	addi	sp,sp,-48
    800033a4:	f406                	sd	ra,40(sp)
    800033a6:	f022                	sd	s0,32(sp)
    800033a8:	ec26                	sd	s1,24(sp)
    800033aa:	e84a                	sd	s2,16(sp)
    800033ac:	e44e                	sd	s3,8(sp)
    800033ae:	e052                	sd	s4,0(sp)
    800033b0:	1800                	addi	s0,sp,48
    800033b2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033b4:	47ad                	li	a5,11
    800033b6:	02b7e763          	bltu	a5,a1,800033e4 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033ba:	02059493          	slli	s1,a1,0x20
    800033be:	9081                	srli	s1,s1,0x20
    800033c0:	048a                	slli	s1,s1,0x2
    800033c2:	94aa                	add	s1,s1,a0
    800033c4:	0504a903          	lw	s2,80(s1)
    800033c8:	06091e63          	bnez	s2,80003444 <bmap+0xa2>
      addr = balloc(ip->dev);
    800033cc:	4108                	lw	a0,0(a0)
    800033ce:	00000097          	auipc	ra,0x0
    800033d2:	e9c080e7          	jalr	-356(ra) # 8000326a <balloc>
    800033d6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033da:	06090563          	beqz	s2,80003444 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033de:	0524a823          	sw	s2,80(s1)
    800033e2:	a08d                	j	80003444 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033e4:	ff45849b          	addiw	s1,a1,-12
    800033e8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033ec:	0ff00793          	li	a5,255
    800033f0:	08e7e563          	bltu	a5,a4,8000347a <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033f4:	08052903          	lw	s2,128(a0)
    800033f8:	00091d63          	bnez	s2,80003412 <bmap+0x70>
      addr = balloc(ip->dev);
    800033fc:	4108                	lw	a0,0(a0)
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	e6c080e7          	jalr	-404(ra) # 8000326a <balloc>
    80003406:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000340a:	02090d63          	beqz	s2,80003444 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000340e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003412:	85ca                	mv	a1,s2
    80003414:	0009a503          	lw	a0,0(s3)
    80003418:	00000097          	auipc	ra,0x0
    8000341c:	b90080e7          	jalr	-1136(ra) # 80002fa8 <bread>
    80003420:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003422:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003426:	02049593          	slli	a1,s1,0x20
    8000342a:	9181                	srli	a1,a1,0x20
    8000342c:	058a                	slli	a1,a1,0x2
    8000342e:	00b784b3          	add	s1,a5,a1
    80003432:	0004a903          	lw	s2,0(s1)
    80003436:	02090063          	beqz	s2,80003456 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000343a:	8552                	mv	a0,s4
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	c9c080e7          	jalr	-868(ra) # 800030d8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003444:	854a                	mv	a0,s2
    80003446:	70a2                	ld	ra,40(sp)
    80003448:	7402                	ld	s0,32(sp)
    8000344a:	64e2                	ld	s1,24(sp)
    8000344c:	6942                	ld	s2,16(sp)
    8000344e:	69a2                	ld	s3,8(sp)
    80003450:	6a02                	ld	s4,0(sp)
    80003452:	6145                	addi	sp,sp,48
    80003454:	8082                	ret
      addr = balloc(ip->dev);
    80003456:	0009a503          	lw	a0,0(s3)
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	e10080e7          	jalr	-496(ra) # 8000326a <balloc>
    80003462:	0005091b          	sext.w	s2,a0
      if(addr){
    80003466:	fc090ae3          	beqz	s2,8000343a <bmap+0x98>
        a[bn] = addr;
    8000346a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000346e:	8552                	mv	a0,s4
    80003470:	00001097          	auipc	ra,0x1
    80003474:	eec080e7          	jalr	-276(ra) # 8000435c <log_write>
    80003478:	b7c9                	j	8000343a <bmap+0x98>
  panic("bmap: out of range");
    8000347a:	00005517          	auipc	a0,0x5
    8000347e:	11e50513          	addi	a0,a0,286 # 80008598 <syscalls+0x128>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	0c2080e7          	jalr	194(ra) # 80000544 <panic>

000000008000348a <iget>:
{
    8000348a:	7179                	addi	sp,sp,-48
    8000348c:	f406                	sd	ra,40(sp)
    8000348e:	f022                	sd	s0,32(sp)
    80003490:	ec26                	sd	s1,24(sp)
    80003492:	e84a                	sd	s2,16(sp)
    80003494:	e44e                	sd	s3,8(sp)
    80003496:	e052                	sd	s4,0(sp)
    80003498:	1800                	addi	s0,sp,48
    8000349a:	89aa                	mv	s3,a0
    8000349c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000349e:	0001c517          	auipc	a0,0x1c
    800034a2:	00a50513          	addi	a0,a0,10 # 8001f4a8 <itable>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	744080e7          	jalr	1860(ra) # 80000bea <acquire>
  empty = 0;
    800034ae:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034b0:	0001c497          	auipc	s1,0x1c
    800034b4:	01048493          	addi	s1,s1,16 # 8001f4c0 <itable+0x18>
    800034b8:	0001e697          	auipc	a3,0x1e
    800034bc:	a9868693          	addi	a3,a3,-1384 # 80020f50 <log>
    800034c0:	a039                	j	800034ce <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034c2:	02090b63          	beqz	s2,800034f8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034c6:	08848493          	addi	s1,s1,136
    800034ca:	02d48a63          	beq	s1,a3,800034fe <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034ce:	449c                	lw	a5,8(s1)
    800034d0:	fef059e3          	blez	a5,800034c2 <iget+0x38>
    800034d4:	4098                	lw	a4,0(s1)
    800034d6:	ff3716e3          	bne	a4,s3,800034c2 <iget+0x38>
    800034da:	40d8                	lw	a4,4(s1)
    800034dc:	ff4713e3          	bne	a4,s4,800034c2 <iget+0x38>
      ip->ref++;
    800034e0:	2785                	addiw	a5,a5,1
    800034e2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034e4:	0001c517          	auipc	a0,0x1c
    800034e8:	fc450513          	addi	a0,a0,-60 # 8001f4a8 <itable>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	7b2080e7          	jalr	1970(ra) # 80000c9e <release>
      return ip;
    800034f4:	8926                	mv	s2,s1
    800034f6:	a03d                	j	80003524 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f8:	f7f9                	bnez	a5,800034c6 <iget+0x3c>
    800034fa:	8926                	mv	s2,s1
    800034fc:	b7e9                	j	800034c6 <iget+0x3c>
  if(empty == 0)
    800034fe:	02090c63          	beqz	s2,80003536 <iget+0xac>
  ip->dev = dev;
    80003502:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003506:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000350a:	4785                	li	a5,1
    8000350c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003510:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003514:	0001c517          	auipc	a0,0x1c
    80003518:	f9450513          	addi	a0,a0,-108 # 8001f4a8 <itable>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	782080e7          	jalr	1922(ra) # 80000c9e <release>
}
    80003524:	854a                	mv	a0,s2
    80003526:	70a2                	ld	ra,40(sp)
    80003528:	7402                	ld	s0,32(sp)
    8000352a:	64e2                	ld	s1,24(sp)
    8000352c:	6942                	ld	s2,16(sp)
    8000352e:	69a2                	ld	s3,8(sp)
    80003530:	6a02                	ld	s4,0(sp)
    80003532:	6145                	addi	sp,sp,48
    80003534:	8082                	ret
    panic("iget: no inodes");
    80003536:	00005517          	auipc	a0,0x5
    8000353a:	07a50513          	addi	a0,a0,122 # 800085b0 <syscalls+0x140>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	006080e7          	jalr	6(ra) # 80000544 <panic>

0000000080003546 <fsinit>:
fsinit(int dev) {
    80003546:	7179                	addi	sp,sp,-48
    80003548:	f406                	sd	ra,40(sp)
    8000354a:	f022                	sd	s0,32(sp)
    8000354c:	ec26                	sd	s1,24(sp)
    8000354e:	e84a                	sd	s2,16(sp)
    80003550:	e44e                	sd	s3,8(sp)
    80003552:	1800                	addi	s0,sp,48
    80003554:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003556:	4585                	li	a1,1
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	a50080e7          	jalr	-1456(ra) # 80002fa8 <bread>
    80003560:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003562:	0001c997          	auipc	s3,0x1c
    80003566:	f2698993          	addi	s3,s3,-218 # 8001f488 <sb>
    8000356a:	02000613          	li	a2,32
    8000356e:	05850593          	addi	a1,a0,88
    80003572:	854e                	mv	a0,s3
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	7d2080e7          	jalr	2002(ra) # 80000d46 <memmove>
  brelse(bp);
    8000357c:	8526                	mv	a0,s1
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	b5a080e7          	jalr	-1190(ra) # 800030d8 <brelse>
  if(sb.magic != FSMAGIC)
    80003586:	0009a703          	lw	a4,0(s3)
    8000358a:	102037b7          	lui	a5,0x10203
    8000358e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003592:	02f71263          	bne	a4,a5,800035b6 <fsinit+0x70>
  initlog(dev, &sb);
    80003596:	0001c597          	auipc	a1,0x1c
    8000359a:	ef258593          	addi	a1,a1,-270 # 8001f488 <sb>
    8000359e:	854a                	mv	a0,s2
    800035a0:	00001097          	auipc	ra,0x1
    800035a4:	b40080e7          	jalr	-1216(ra) # 800040e0 <initlog>
}
    800035a8:	70a2                	ld	ra,40(sp)
    800035aa:	7402                	ld	s0,32(sp)
    800035ac:	64e2                	ld	s1,24(sp)
    800035ae:	6942                	ld	s2,16(sp)
    800035b0:	69a2                	ld	s3,8(sp)
    800035b2:	6145                	addi	sp,sp,48
    800035b4:	8082                	ret
    panic("invalid file system");
    800035b6:	00005517          	auipc	a0,0x5
    800035ba:	00a50513          	addi	a0,a0,10 # 800085c0 <syscalls+0x150>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	f86080e7          	jalr	-122(ra) # 80000544 <panic>

00000000800035c6 <iinit>:
{
    800035c6:	7179                	addi	sp,sp,-48
    800035c8:	f406                	sd	ra,40(sp)
    800035ca:	f022                	sd	s0,32(sp)
    800035cc:	ec26                	sd	s1,24(sp)
    800035ce:	e84a                	sd	s2,16(sp)
    800035d0:	e44e                	sd	s3,8(sp)
    800035d2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035d4:	00005597          	auipc	a1,0x5
    800035d8:	00458593          	addi	a1,a1,4 # 800085d8 <syscalls+0x168>
    800035dc:	0001c517          	auipc	a0,0x1c
    800035e0:	ecc50513          	addi	a0,a0,-308 # 8001f4a8 <itable>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	576080e7          	jalr	1398(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800035ec:	0001c497          	auipc	s1,0x1c
    800035f0:	ee448493          	addi	s1,s1,-284 # 8001f4d0 <itable+0x28>
    800035f4:	0001e997          	auipc	s3,0x1e
    800035f8:	96c98993          	addi	s3,s3,-1684 # 80020f60 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035fc:	00005917          	auipc	s2,0x5
    80003600:	fe490913          	addi	s2,s2,-28 # 800085e0 <syscalls+0x170>
    80003604:	85ca                	mv	a1,s2
    80003606:	8526                	mv	a0,s1
    80003608:	00001097          	auipc	ra,0x1
    8000360c:	e3a080e7          	jalr	-454(ra) # 80004442 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003610:	08848493          	addi	s1,s1,136
    80003614:	ff3498e3          	bne	s1,s3,80003604 <iinit+0x3e>
}
    80003618:	70a2                	ld	ra,40(sp)
    8000361a:	7402                	ld	s0,32(sp)
    8000361c:	64e2                	ld	s1,24(sp)
    8000361e:	6942                	ld	s2,16(sp)
    80003620:	69a2                	ld	s3,8(sp)
    80003622:	6145                	addi	sp,sp,48
    80003624:	8082                	ret

0000000080003626 <ialloc>:
{
    80003626:	715d                	addi	sp,sp,-80
    80003628:	e486                	sd	ra,72(sp)
    8000362a:	e0a2                	sd	s0,64(sp)
    8000362c:	fc26                	sd	s1,56(sp)
    8000362e:	f84a                	sd	s2,48(sp)
    80003630:	f44e                	sd	s3,40(sp)
    80003632:	f052                	sd	s4,32(sp)
    80003634:	ec56                	sd	s5,24(sp)
    80003636:	e85a                	sd	s6,16(sp)
    80003638:	e45e                	sd	s7,8(sp)
    8000363a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000363c:	0001c717          	auipc	a4,0x1c
    80003640:	e5872703          	lw	a4,-424(a4) # 8001f494 <sb+0xc>
    80003644:	4785                	li	a5,1
    80003646:	04e7fa63          	bgeu	a5,a4,8000369a <ialloc+0x74>
    8000364a:	8aaa                	mv	s5,a0
    8000364c:	8bae                	mv	s7,a1
    8000364e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003650:	0001ca17          	auipc	s4,0x1c
    80003654:	e38a0a13          	addi	s4,s4,-456 # 8001f488 <sb>
    80003658:	00048b1b          	sext.w	s6,s1
    8000365c:	0044d593          	srli	a1,s1,0x4
    80003660:	018a2783          	lw	a5,24(s4)
    80003664:	9dbd                	addw	a1,a1,a5
    80003666:	8556                	mv	a0,s5
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	940080e7          	jalr	-1728(ra) # 80002fa8 <bread>
    80003670:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003672:	05850993          	addi	s3,a0,88
    80003676:	00f4f793          	andi	a5,s1,15
    8000367a:	079a                	slli	a5,a5,0x6
    8000367c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000367e:	00099783          	lh	a5,0(s3)
    80003682:	c3a1                	beqz	a5,800036c2 <ialloc+0x9c>
    brelse(bp);
    80003684:	00000097          	auipc	ra,0x0
    80003688:	a54080e7          	jalr	-1452(ra) # 800030d8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000368c:	0485                	addi	s1,s1,1
    8000368e:	00ca2703          	lw	a4,12(s4)
    80003692:	0004879b          	sext.w	a5,s1
    80003696:	fce7e1e3          	bltu	a5,a4,80003658 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000369a:	00005517          	auipc	a0,0x5
    8000369e:	f4e50513          	addi	a0,a0,-178 # 800085e8 <syscalls+0x178>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	eec080e7          	jalr	-276(ra) # 8000058e <printf>
  return 0;
    800036aa:	4501                	li	a0,0
}
    800036ac:	60a6                	ld	ra,72(sp)
    800036ae:	6406                	ld	s0,64(sp)
    800036b0:	74e2                	ld	s1,56(sp)
    800036b2:	7942                	ld	s2,48(sp)
    800036b4:	79a2                	ld	s3,40(sp)
    800036b6:	7a02                	ld	s4,32(sp)
    800036b8:	6ae2                	ld	s5,24(sp)
    800036ba:	6b42                	ld	s6,16(sp)
    800036bc:	6ba2                	ld	s7,8(sp)
    800036be:	6161                	addi	sp,sp,80
    800036c0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036c2:	04000613          	li	a2,64
    800036c6:	4581                	li	a1,0
    800036c8:	854e                	mv	a0,s3
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	61c080e7          	jalr	1564(ra) # 80000ce6 <memset>
      dip->type = type;
    800036d2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036d6:	854a                	mv	a0,s2
    800036d8:	00001097          	auipc	ra,0x1
    800036dc:	c84080e7          	jalr	-892(ra) # 8000435c <log_write>
      brelse(bp);
    800036e0:	854a                	mv	a0,s2
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	9f6080e7          	jalr	-1546(ra) # 800030d8 <brelse>
      return iget(dev, inum);
    800036ea:	85da                	mv	a1,s6
    800036ec:	8556                	mv	a0,s5
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	d9c080e7          	jalr	-612(ra) # 8000348a <iget>
    800036f6:	bf5d                	j	800036ac <ialloc+0x86>

00000000800036f8 <iupdate>:
{
    800036f8:	1101                	addi	sp,sp,-32
    800036fa:	ec06                	sd	ra,24(sp)
    800036fc:	e822                	sd	s0,16(sp)
    800036fe:	e426                	sd	s1,8(sp)
    80003700:	e04a                	sd	s2,0(sp)
    80003702:	1000                	addi	s0,sp,32
    80003704:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003706:	415c                	lw	a5,4(a0)
    80003708:	0047d79b          	srliw	a5,a5,0x4
    8000370c:	0001c597          	auipc	a1,0x1c
    80003710:	d945a583          	lw	a1,-620(a1) # 8001f4a0 <sb+0x18>
    80003714:	9dbd                	addw	a1,a1,a5
    80003716:	4108                	lw	a0,0(a0)
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	890080e7          	jalr	-1904(ra) # 80002fa8 <bread>
    80003720:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003722:	05850793          	addi	a5,a0,88
    80003726:	40c8                	lw	a0,4(s1)
    80003728:	893d                	andi	a0,a0,15
    8000372a:	051a                	slli	a0,a0,0x6
    8000372c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000372e:	04449703          	lh	a4,68(s1)
    80003732:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003736:	04649703          	lh	a4,70(s1)
    8000373a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000373e:	04849703          	lh	a4,72(s1)
    80003742:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003746:	04a49703          	lh	a4,74(s1)
    8000374a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000374e:	44f8                	lw	a4,76(s1)
    80003750:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003752:	03400613          	li	a2,52
    80003756:	05048593          	addi	a1,s1,80
    8000375a:	0531                	addi	a0,a0,12
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	5ea080e7          	jalr	1514(ra) # 80000d46 <memmove>
  log_write(bp);
    80003764:	854a                	mv	a0,s2
    80003766:	00001097          	auipc	ra,0x1
    8000376a:	bf6080e7          	jalr	-1034(ra) # 8000435c <log_write>
  brelse(bp);
    8000376e:	854a                	mv	a0,s2
    80003770:	00000097          	auipc	ra,0x0
    80003774:	968080e7          	jalr	-1688(ra) # 800030d8 <brelse>
}
    80003778:	60e2                	ld	ra,24(sp)
    8000377a:	6442                	ld	s0,16(sp)
    8000377c:	64a2                	ld	s1,8(sp)
    8000377e:	6902                	ld	s2,0(sp)
    80003780:	6105                	addi	sp,sp,32
    80003782:	8082                	ret

0000000080003784 <idup>:
{
    80003784:	1101                	addi	sp,sp,-32
    80003786:	ec06                	sd	ra,24(sp)
    80003788:	e822                	sd	s0,16(sp)
    8000378a:	e426                	sd	s1,8(sp)
    8000378c:	1000                	addi	s0,sp,32
    8000378e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003790:	0001c517          	auipc	a0,0x1c
    80003794:	d1850513          	addi	a0,a0,-744 # 8001f4a8 <itable>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	452080e7          	jalr	1106(ra) # 80000bea <acquire>
  ip->ref++;
    800037a0:	449c                	lw	a5,8(s1)
    800037a2:	2785                	addiw	a5,a5,1
    800037a4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037a6:	0001c517          	auipc	a0,0x1c
    800037aa:	d0250513          	addi	a0,a0,-766 # 8001f4a8 <itable>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	4f0080e7          	jalr	1264(ra) # 80000c9e <release>
}
    800037b6:	8526                	mv	a0,s1
    800037b8:	60e2                	ld	ra,24(sp)
    800037ba:	6442                	ld	s0,16(sp)
    800037bc:	64a2                	ld	s1,8(sp)
    800037be:	6105                	addi	sp,sp,32
    800037c0:	8082                	ret

00000000800037c2 <ilock>:
{
    800037c2:	1101                	addi	sp,sp,-32
    800037c4:	ec06                	sd	ra,24(sp)
    800037c6:	e822                	sd	s0,16(sp)
    800037c8:	e426                	sd	s1,8(sp)
    800037ca:	e04a                	sd	s2,0(sp)
    800037cc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037ce:	c115                	beqz	a0,800037f2 <ilock+0x30>
    800037d0:	84aa                	mv	s1,a0
    800037d2:	451c                	lw	a5,8(a0)
    800037d4:	00f05f63          	blez	a5,800037f2 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037d8:	0541                	addi	a0,a0,16
    800037da:	00001097          	auipc	ra,0x1
    800037de:	ca2080e7          	jalr	-862(ra) # 8000447c <acquiresleep>
  if(ip->valid == 0){
    800037e2:	40bc                	lw	a5,64(s1)
    800037e4:	cf99                	beqz	a5,80003802 <ilock+0x40>
}
    800037e6:	60e2                	ld	ra,24(sp)
    800037e8:	6442                	ld	s0,16(sp)
    800037ea:	64a2                	ld	s1,8(sp)
    800037ec:	6902                	ld	s2,0(sp)
    800037ee:	6105                	addi	sp,sp,32
    800037f0:	8082                	ret
    panic("ilock");
    800037f2:	00005517          	auipc	a0,0x5
    800037f6:	e0e50513          	addi	a0,a0,-498 # 80008600 <syscalls+0x190>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	d4a080e7          	jalr	-694(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003802:	40dc                	lw	a5,4(s1)
    80003804:	0047d79b          	srliw	a5,a5,0x4
    80003808:	0001c597          	auipc	a1,0x1c
    8000380c:	c985a583          	lw	a1,-872(a1) # 8001f4a0 <sb+0x18>
    80003810:	9dbd                	addw	a1,a1,a5
    80003812:	4088                	lw	a0,0(s1)
    80003814:	fffff097          	auipc	ra,0xfffff
    80003818:	794080e7          	jalr	1940(ra) # 80002fa8 <bread>
    8000381c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000381e:	05850593          	addi	a1,a0,88
    80003822:	40dc                	lw	a5,4(s1)
    80003824:	8bbd                	andi	a5,a5,15
    80003826:	079a                	slli	a5,a5,0x6
    80003828:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000382a:	00059783          	lh	a5,0(a1)
    8000382e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003832:	00259783          	lh	a5,2(a1)
    80003836:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000383a:	00459783          	lh	a5,4(a1)
    8000383e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003842:	00659783          	lh	a5,6(a1)
    80003846:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000384a:	459c                	lw	a5,8(a1)
    8000384c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000384e:	03400613          	li	a2,52
    80003852:	05b1                	addi	a1,a1,12
    80003854:	05048513          	addi	a0,s1,80
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	4ee080e7          	jalr	1262(ra) # 80000d46 <memmove>
    brelse(bp);
    80003860:	854a                	mv	a0,s2
    80003862:	00000097          	auipc	ra,0x0
    80003866:	876080e7          	jalr	-1930(ra) # 800030d8 <brelse>
    ip->valid = 1;
    8000386a:	4785                	li	a5,1
    8000386c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000386e:	04449783          	lh	a5,68(s1)
    80003872:	fbb5                	bnez	a5,800037e6 <ilock+0x24>
      panic("ilock: no type");
    80003874:	00005517          	auipc	a0,0x5
    80003878:	d9450513          	addi	a0,a0,-620 # 80008608 <syscalls+0x198>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	cc8080e7          	jalr	-824(ra) # 80000544 <panic>

0000000080003884 <iunlock>:
{
    80003884:	1101                	addi	sp,sp,-32
    80003886:	ec06                	sd	ra,24(sp)
    80003888:	e822                	sd	s0,16(sp)
    8000388a:	e426                	sd	s1,8(sp)
    8000388c:	e04a                	sd	s2,0(sp)
    8000388e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003890:	c905                	beqz	a0,800038c0 <iunlock+0x3c>
    80003892:	84aa                	mv	s1,a0
    80003894:	01050913          	addi	s2,a0,16
    80003898:	854a                	mv	a0,s2
    8000389a:	00001097          	auipc	ra,0x1
    8000389e:	c7c080e7          	jalr	-900(ra) # 80004516 <holdingsleep>
    800038a2:	cd19                	beqz	a0,800038c0 <iunlock+0x3c>
    800038a4:	449c                	lw	a5,8(s1)
    800038a6:	00f05d63          	blez	a5,800038c0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038aa:	854a                	mv	a0,s2
    800038ac:	00001097          	auipc	ra,0x1
    800038b0:	c26080e7          	jalr	-986(ra) # 800044d2 <releasesleep>
}
    800038b4:	60e2                	ld	ra,24(sp)
    800038b6:	6442                	ld	s0,16(sp)
    800038b8:	64a2                	ld	s1,8(sp)
    800038ba:	6902                	ld	s2,0(sp)
    800038bc:	6105                	addi	sp,sp,32
    800038be:	8082                	ret
    panic("iunlock");
    800038c0:	00005517          	auipc	a0,0x5
    800038c4:	d5850513          	addi	a0,a0,-680 # 80008618 <syscalls+0x1a8>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	c7c080e7          	jalr	-900(ra) # 80000544 <panic>

00000000800038d0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038d0:	7179                	addi	sp,sp,-48
    800038d2:	f406                	sd	ra,40(sp)
    800038d4:	f022                	sd	s0,32(sp)
    800038d6:	ec26                	sd	s1,24(sp)
    800038d8:	e84a                	sd	s2,16(sp)
    800038da:	e44e                	sd	s3,8(sp)
    800038dc:	e052                	sd	s4,0(sp)
    800038de:	1800                	addi	s0,sp,48
    800038e0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038e2:	05050493          	addi	s1,a0,80
    800038e6:	08050913          	addi	s2,a0,128
    800038ea:	a021                	j	800038f2 <itrunc+0x22>
    800038ec:	0491                	addi	s1,s1,4
    800038ee:	01248d63          	beq	s1,s2,80003908 <itrunc+0x38>
    if(ip->addrs[i]){
    800038f2:	408c                	lw	a1,0(s1)
    800038f4:	dde5                	beqz	a1,800038ec <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038f6:	0009a503          	lw	a0,0(s3)
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	8f4080e7          	jalr	-1804(ra) # 800031ee <bfree>
      ip->addrs[i] = 0;
    80003902:	0004a023          	sw	zero,0(s1)
    80003906:	b7dd                	j	800038ec <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003908:	0809a583          	lw	a1,128(s3)
    8000390c:	e185                	bnez	a1,8000392c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000390e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003912:	854e                	mv	a0,s3
    80003914:	00000097          	auipc	ra,0x0
    80003918:	de4080e7          	jalr	-540(ra) # 800036f8 <iupdate>
}
    8000391c:	70a2                	ld	ra,40(sp)
    8000391e:	7402                	ld	s0,32(sp)
    80003920:	64e2                	ld	s1,24(sp)
    80003922:	6942                	ld	s2,16(sp)
    80003924:	69a2                	ld	s3,8(sp)
    80003926:	6a02                	ld	s4,0(sp)
    80003928:	6145                	addi	sp,sp,48
    8000392a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000392c:	0009a503          	lw	a0,0(s3)
    80003930:	fffff097          	auipc	ra,0xfffff
    80003934:	678080e7          	jalr	1656(ra) # 80002fa8 <bread>
    80003938:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000393a:	05850493          	addi	s1,a0,88
    8000393e:	45850913          	addi	s2,a0,1112
    80003942:	a811                	j	80003956 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003944:	0009a503          	lw	a0,0(s3)
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	8a6080e7          	jalr	-1882(ra) # 800031ee <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003950:	0491                	addi	s1,s1,4
    80003952:	01248563          	beq	s1,s2,8000395c <itrunc+0x8c>
      if(a[j])
    80003956:	408c                	lw	a1,0(s1)
    80003958:	dde5                	beqz	a1,80003950 <itrunc+0x80>
    8000395a:	b7ed                	j	80003944 <itrunc+0x74>
    brelse(bp);
    8000395c:	8552                	mv	a0,s4
    8000395e:	fffff097          	auipc	ra,0xfffff
    80003962:	77a080e7          	jalr	1914(ra) # 800030d8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003966:	0809a583          	lw	a1,128(s3)
    8000396a:	0009a503          	lw	a0,0(s3)
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	880080e7          	jalr	-1920(ra) # 800031ee <bfree>
    ip->addrs[NDIRECT] = 0;
    80003976:	0809a023          	sw	zero,128(s3)
    8000397a:	bf51                	j	8000390e <itrunc+0x3e>

000000008000397c <iput>:
{
    8000397c:	1101                	addi	sp,sp,-32
    8000397e:	ec06                	sd	ra,24(sp)
    80003980:	e822                	sd	s0,16(sp)
    80003982:	e426                	sd	s1,8(sp)
    80003984:	e04a                	sd	s2,0(sp)
    80003986:	1000                	addi	s0,sp,32
    80003988:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000398a:	0001c517          	auipc	a0,0x1c
    8000398e:	b1e50513          	addi	a0,a0,-1250 # 8001f4a8 <itable>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	258080e7          	jalr	600(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000399a:	4498                	lw	a4,8(s1)
    8000399c:	4785                	li	a5,1
    8000399e:	02f70363          	beq	a4,a5,800039c4 <iput+0x48>
  ip->ref--;
    800039a2:	449c                	lw	a5,8(s1)
    800039a4:	37fd                	addiw	a5,a5,-1
    800039a6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039a8:	0001c517          	auipc	a0,0x1c
    800039ac:	b0050513          	addi	a0,a0,-1280 # 8001f4a8 <itable>
    800039b0:	ffffd097          	auipc	ra,0xffffd
    800039b4:	2ee080e7          	jalr	750(ra) # 80000c9e <release>
}
    800039b8:	60e2                	ld	ra,24(sp)
    800039ba:	6442                	ld	s0,16(sp)
    800039bc:	64a2                	ld	s1,8(sp)
    800039be:	6902                	ld	s2,0(sp)
    800039c0:	6105                	addi	sp,sp,32
    800039c2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039c4:	40bc                	lw	a5,64(s1)
    800039c6:	dff1                	beqz	a5,800039a2 <iput+0x26>
    800039c8:	04a49783          	lh	a5,74(s1)
    800039cc:	fbf9                	bnez	a5,800039a2 <iput+0x26>
    acquiresleep(&ip->lock);
    800039ce:	01048913          	addi	s2,s1,16
    800039d2:	854a                	mv	a0,s2
    800039d4:	00001097          	auipc	ra,0x1
    800039d8:	aa8080e7          	jalr	-1368(ra) # 8000447c <acquiresleep>
    release(&itable.lock);
    800039dc:	0001c517          	auipc	a0,0x1c
    800039e0:	acc50513          	addi	a0,a0,-1332 # 8001f4a8 <itable>
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	2ba080e7          	jalr	698(ra) # 80000c9e <release>
    itrunc(ip);
    800039ec:	8526                	mv	a0,s1
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	ee2080e7          	jalr	-286(ra) # 800038d0 <itrunc>
    ip->type = 0;
    800039f6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039fa:	8526                	mv	a0,s1
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	cfc080e7          	jalr	-772(ra) # 800036f8 <iupdate>
    ip->valid = 0;
    80003a04:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a08:	854a                	mv	a0,s2
    80003a0a:	00001097          	auipc	ra,0x1
    80003a0e:	ac8080e7          	jalr	-1336(ra) # 800044d2 <releasesleep>
    acquire(&itable.lock);
    80003a12:	0001c517          	auipc	a0,0x1c
    80003a16:	a9650513          	addi	a0,a0,-1386 # 8001f4a8 <itable>
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	1d0080e7          	jalr	464(ra) # 80000bea <acquire>
    80003a22:	b741                	j	800039a2 <iput+0x26>

0000000080003a24 <iunlockput>:
{
    80003a24:	1101                	addi	sp,sp,-32
    80003a26:	ec06                	sd	ra,24(sp)
    80003a28:	e822                	sd	s0,16(sp)
    80003a2a:	e426                	sd	s1,8(sp)
    80003a2c:	1000                	addi	s0,sp,32
    80003a2e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	e54080e7          	jalr	-428(ra) # 80003884 <iunlock>
  iput(ip);
    80003a38:	8526                	mv	a0,s1
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	f42080e7          	jalr	-190(ra) # 8000397c <iput>
}
    80003a42:	60e2                	ld	ra,24(sp)
    80003a44:	6442                	ld	s0,16(sp)
    80003a46:	64a2                	ld	s1,8(sp)
    80003a48:	6105                	addi	sp,sp,32
    80003a4a:	8082                	ret

0000000080003a4c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a4c:	1141                	addi	sp,sp,-16
    80003a4e:	e422                	sd	s0,8(sp)
    80003a50:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a52:	411c                	lw	a5,0(a0)
    80003a54:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a56:	415c                	lw	a5,4(a0)
    80003a58:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a5a:	04451783          	lh	a5,68(a0)
    80003a5e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a62:	04a51783          	lh	a5,74(a0)
    80003a66:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a6a:	04c56783          	lwu	a5,76(a0)
    80003a6e:	e99c                	sd	a5,16(a1)
}
    80003a70:	6422                	ld	s0,8(sp)
    80003a72:	0141                	addi	sp,sp,16
    80003a74:	8082                	ret

0000000080003a76 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a76:	457c                	lw	a5,76(a0)
    80003a78:	0ed7e963          	bltu	a5,a3,80003b6a <readi+0xf4>
{
    80003a7c:	7159                	addi	sp,sp,-112
    80003a7e:	f486                	sd	ra,104(sp)
    80003a80:	f0a2                	sd	s0,96(sp)
    80003a82:	eca6                	sd	s1,88(sp)
    80003a84:	e8ca                	sd	s2,80(sp)
    80003a86:	e4ce                	sd	s3,72(sp)
    80003a88:	e0d2                	sd	s4,64(sp)
    80003a8a:	fc56                	sd	s5,56(sp)
    80003a8c:	f85a                	sd	s6,48(sp)
    80003a8e:	f45e                	sd	s7,40(sp)
    80003a90:	f062                	sd	s8,32(sp)
    80003a92:	ec66                	sd	s9,24(sp)
    80003a94:	e86a                	sd	s10,16(sp)
    80003a96:	e46e                	sd	s11,8(sp)
    80003a98:	1880                	addi	s0,sp,112
    80003a9a:	8b2a                	mv	s6,a0
    80003a9c:	8bae                	mv	s7,a1
    80003a9e:	8a32                	mv	s4,a2
    80003aa0:	84b6                	mv	s1,a3
    80003aa2:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003aa4:	9f35                	addw	a4,a4,a3
    return 0;
    80003aa6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aa8:	0ad76063          	bltu	a4,a3,80003b48 <readi+0xd2>
  if(off + n > ip->size)
    80003aac:	00e7f463          	bgeu	a5,a4,80003ab4 <readi+0x3e>
    n = ip->size - off;
    80003ab0:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab4:	0a0a8963          	beqz	s5,80003b66 <readi+0xf0>
    80003ab8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aba:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003abe:	5c7d                	li	s8,-1
    80003ac0:	a82d                	j	80003afa <readi+0x84>
    80003ac2:	020d1d93          	slli	s11,s10,0x20
    80003ac6:	020ddd93          	srli	s11,s11,0x20
    80003aca:	05890613          	addi	a2,s2,88
    80003ace:	86ee                	mv	a3,s11
    80003ad0:	963a                	add	a2,a2,a4
    80003ad2:	85d2                	mv	a1,s4
    80003ad4:	855e                	mv	a0,s7
    80003ad6:	fffff097          	auipc	ra,0xfffff
    80003ada:	a1e080e7          	jalr	-1506(ra) # 800024f4 <either_copyout>
    80003ade:	05850d63          	beq	a0,s8,80003b38 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ae2:	854a                	mv	a0,s2
    80003ae4:	fffff097          	auipc	ra,0xfffff
    80003ae8:	5f4080e7          	jalr	1524(ra) # 800030d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aec:	013d09bb          	addw	s3,s10,s3
    80003af0:	009d04bb          	addw	s1,s10,s1
    80003af4:	9a6e                	add	s4,s4,s11
    80003af6:	0559f763          	bgeu	s3,s5,80003b44 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003afa:	00a4d59b          	srliw	a1,s1,0xa
    80003afe:	855a                	mv	a0,s6
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	8a2080e7          	jalr	-1886(ra) # 800033a2 <bmap>
    80003b08:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b0c:	cd85                	beqz	a1,80003b44 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b0e:	000b2503          	lw	a0,0(s6)
    80003b12:	fffff097          	auipc	ra,0xfffff
    80003b16:	496080e7          	jalr	1174(ra) # 80002fa8 <bread>
    80003b1a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b1c:	3ff4f713          	andi	a4,s1,1023
    80003b20:	40ec87bb          	subw	a5,s9,a4
    80003b24:	413a86bb          	subw	a3,s5,s3
    80003b28:	8d3e                	mv	s10,a5
    80003b2a:	2781                	sext.w	a5,a5
    80003b2c:	0006861b          	sext.w	a2,a3
    80003b30:	f8f679e3          	bgeu	a2,a5,80003ac2 <readi+0x4c>
    80003b34:	8d36                	mv	s10,a3
    80003b36:	b771                	j	80003ac2 <readi+0x4c>
      brelse(bp);
    80003b38:	854a                	mv	a0,s2
    80003b3a:	fffff097          	auipc	ra,0xfffff
    80003b3e:	59e080e7          	jalr	1438(ra) # 800030d8 <brelse>
      tot = -1;
    80003b42:	59fd                	li	s3,-1
  }
  return tot;
    80003b44:	0009851b          	sext.w	a0,s3
}
    80003b48:	70a6                	ld	ra,104(sp)
    80003b4a:	7406                	ld	s0,96(sp)
    80003b4c:	64e6                	ld	s1,88(sp)
    80003b4e:	6946                	ld	s2,80(sp)
    80003b50:	69a6                	ld	s3,72(sp)
    80003b52:	6a06                	ld	s4,64(sp)
    80003b54:	7ae2                	ld	s5,56(sp)
    80003b56:	7b42                	ld	s6,48(sp)
    80003b58:	7ba2                	ld	s7,40(sp)
    80003b5a:	7c02                	ld	s8,32(sp)
    80003b5c:	6ce2                	ld	s9,24(sp)
    80003b5e:	6d42                	ld	s10,16(sp)
    80003b60:	6da2                	ld	s11,8(sp)
    80003b62:	6165                	addi	sp,sp,112
    80003b64:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b66:	89d6                	mv	s3,s5
    80003b68:	bff1                	j	80003b44 <readi+0xce>
    return 0;
    80003b6a:	4501                	li	a0,0
}
    80003b6c:	8082                	ret

0000000080003b6e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b6e:	457c                	lw	a5,76(a0)
    80003b70:	10d7e863          	bltu	a5,a3,80003c80 <writei+0x112>
{
    80003b74:	7159                	addi	sp,sp,-112
    80003b76:	f486                	sd	ra,104(sp)
    80003b78:	f0a2                	sd	s0,96(sp)
    80003b7a:	eca6                	sd	s1,88(sp)
    80003b7c:	e8ca                	sd	s2,80(sp)
    80003b7e:	e4ce                	sd	s3,72(sp)
    80003b80:	e0d2                	sd	s4,64(sp)
    80003b82:	fc56                	sd	s5,56(sp)
    80003b84:	f85a                	sd	s6,48(sp)
    80003b86:	f45e                	sd	s7,40(sp)
    80003b88:	f062                	sd	s8,32(sp)
    80003b8a:	ec66                	sd	s9,24(sp)
    80003b8c:	e86a                	sd	s10,16(sp)
    80003b8e:	e46e                	sd	s11,8(sp)
    80003b90:	1880                	addi	s0,sp,112
    80003b92:	8aaa                	mv	s5,a0
    80003b94:	8bae                	mv	s7,a1
    80003b96:	8a32                	mv	s4,a2
    80003b98:	8936                	mv	s2,a3
    80003b9a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b9c:	00e687bb          	addw	a5,a3,a4
    80003ba0:	0ed7e263          	bltu	a5,a3,80003c84 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ba4:	00043737          	lui	a4,0x43
    80003ba8:	0ef76063          	bltu	a4,a5,80003c88 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bac:	0c0b0863          	beqz	s6,80003c7c <writei+0x10e>
    80003bb0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb2:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bb6:	5c7d                	li	s8,-1
    80003bb8:	a091                	j	80003bfc <writei+0x8e>
    80003bba:	020d1d93          	slli	s11,s10,0x20
    80003bbe:	020ddd93          	srli	s11,s11,0x20
    80003bc2:	05848513          	addi	a0,s1,88
    80003bc6:	86ee                	mv	a3,s11
    80003bc8:	8652                	mv	a2,s4
    80003bca:	85de                	mv	a1,s7
    80003bcc:	953a                	add	a0,a0,a4
    80003bce:	fffff097          	auipc	ra,0xfffff
    80003bd2:	97c080e7          	jalr	-1668(ra) # 8000254a <either_copyin>
    80003bd6:	07850263          	beq	a0,s8,80003c3a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bda:	8526                	mv	a0,s1
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	780080e7          	jalr	1920(ra) # 8000435c <log_write>
    brelse(bp);
    80003be4:	8526                	mv	a0,s1
    80003be6:	fffff097          	auipc	ra,0xfffff
    80003bea:	4f2080e7          	jalr	1266(ra) # 800030d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bee:	013d09bb          	addw	s3,s10,s3
    80003bf2:	012d093b          	addw	s2,s10,s2
    80003bf6:	9a6e                	add	s4,s4,s11
    80003bf8:	0569f663          	bgeu	s3,s6,80003c44 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bfc:	00a9559b          	srliw	a1,s2,0xa
    80003c00:	8556                	mv	a0,s5
    80003c02:	fffff097          	auipc	ra,0xfffff
    80003c06:	7a0080e7          	jalr	1952(ra) # 800033a2 <bmap>
    80003c0a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c0e:	c99d                	beqz	a1,80003c44 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c10:	000aa503          	lw	a0,0(s5)
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	394080e7          	jalr	916(ra) # 80002fa8 <bread>
    80003c1c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c1e:	3ff97713          	andi	a4,s2,1023
    80003c22:	40ec87bb          	subw	a5,s9,a4
    80003c26:	413b06bb          	subw	a3,s6,s3
    80003c2a:	8d3e                	mv	s10,a5
    80003c2c:	2781                	sext.w	a5,a5
    80003c2e:	0006861b          	sext.w	a2,a3
    80003c32:	f8f674e3          	bgeu	a2,a5,80003bba <writei+0x4c>
    80003c36:	8d36                	mv	s10,a3
    80003c38:	b749                	j	80003bba <writei+0x4c>
      brelse(bp);
    80003c3a:	8526                	mv	a0,s1
    80003c3c:	fffff097          	auipc	ra,0xfffff
    80003c40:	49c080e7          	jalr	1180(ra) # 800030d8 <brelse>
  }

  if(off > ip->size)
    80003c44:	04caa783          	lw	a5,76(s5)
    80003c48:	0127f463          	bgeu	a5,s2,80003c50 <writei+0xe2>
    ip->size = off;
    80003c4c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c50:	8556                	mv	a0,s5
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	aa6080e7          	jalr	-1370(ra) # 800036f8 <iupdate>

  return tot;
    80003c5a:	0009851b          	sext.w	a0,s3
}
    80003c5e:	70a6                	ld	ra,104(sp)
    80003c60:	7406                	ld	s0,96(sp)
    80003c62:	64e6                	ld	s1,88(sp)
    80003c64:	6946                	ld	s2,80(sp)
    80003c66:	69a6                	ld	s3,72(sp)
    80003c68:	6a06                	ld	s4,64(sp)
    80003c6a:	7ae2                	ld	s5,56(sp)
    80003c6c:	7b42                	ld	s6,48(sp)
    80003c6e:	7ba2                	ld	s7,40(sp)
    80003c70:	7c02                	ld	s8,32(sp)
    80003c72:	6ce2                	ld	s9,24(sp)
    80003c74:	6d42                	ld	s10,16(sp)
    80003c76:	6da2                	ld	s11,8(sp)
    80003c78:	6165                	addi	sp,sp,112
    80003c7a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c7c:	89da                	mv	s3,s6
    80003c7e:	bfc9                	j	80003c50 <writei+0xe2>
    return -1;
    80003c80:	557d                	li	a0,-1
}
    80003c82:	8082                	ret
    return -1;
    80003c84:	557d                	li	a0,-1
    80003c86:	bfe1                	j	80003c5e <writei+0xf0>
    return -1;
    80003c88:	557d                	li	a0,-1
    80003c8a:	bfd1                	j	80003c5e <writei+0xf0>

0000000080003c8c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c8c:	1141                	addi	sp,sp,-16
    80003c8e:	e406                	sd	ra,8(sp)
    80003c90:	e022                	sd	s0,0(sp)
    80003c92:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c94:	4639                	li	a2,14
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	128080e7          	jalr	296(ra) # 80000dbe <strncmp>
}
    80003c9e:	60a2                	ld	ra,8(sp)
    80003ca0:	6402                	ld	s0,0(sp)
    80003ca2:	0141                	addi	sp,sp,16
    80003ca4:	8082                	ret

0000000080003ca6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ca6:	7139                	addi	sp,sp,-64
    80003ca8:	fc06                	sd	ra,56(sp)
    80003caa:	f822                	sd	s0,48(sp)
    80003cac:	f426                	sd	s1,40(sp)
    80003cae:	f04a                	sd	s2,32(sp)
    80003cb0:	ec4e                	sd	s3,24(sp)
    80003cb2:	e852                	sd	s4,16(sp)
    80003cb4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cb6:	04451703          	lh	a4,68(a0)
    80003cba:	4785                	li	a5,1
    80003cbc:	00f71a63          	bne	a4,a5,80003cd0 <dirlookup+0x2a>
    80003cc0:	892a                	mv	s2,a0
    80003cc2:	89ae                	mv	s3,a1
    80003cc4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc6:	457c                	lw	a5,76(a0)
    80003cc8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cca:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ccc:	e79d                	bnez	a5,80003cfa <dirlookup+0x54>
    80003cce:	a8a5                	j	80003d46 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cd0:	00005517          	auipc	a0,0x5
    80003cd4:	95050513          	addi	a0,a0,-1712 # 80008620 <syscalls+0x1b0>
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	86c080e7          	jalr	-1940(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003ce0:	00005517          	auipc	a0,0x5
    80003ce4:	95850513          	addi	a0,a0,-1704 # 80008638 <syscalls+0x1c8>
    80003ce8:	ffffd097          	auipc	ra,0xffffd
    80003cec:	85c080e7          	jalr	-1956(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf0:	24c1                	addiw	s1,s1,16
    80003cf2:	04c92783          	lw	a5,76(s2)
    80003cf6:	04f4f763          	bgeu	s1,a5,80003d44 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cfa:	4741                	li	a4,16
    80003cfc:	86a6                	mv	a3,s1
    80003cfe:	fc040613          	addi	a2,s0,-64
    80003d02:	4581                	li	a1,0
    80003d04:	854a                	mv	a0,s2
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	d70080e7          	jalr	-656(ra) # 80003a76 <readi>
    80003d0e:	47c1                	li	a5,16
    80003d10:	fcf518e3          	bne	a0,a5,80003ce0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d14:	fc045783          	lhu	a5,-64(s0)
    80003d18:	dfe1                	beqz	a5,80003cf0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d1a:	fc240593          	addi	a1,s0,-62
    80003d1e:	854e                	mv	a0,s3
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	f6c080e7          	jalr	-148(ra) # 80003c8c <namecmp>
    80003d28:	f561                	bnez	a0,80003cf0 <dirlookup+0x4a>
      if(poff)
    80003d2a:	000a0463          	beqz	s4,80003d32 <dirlookup+0x8c>
        *poff = off;
    80003d2e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d32:	fc045583          	lhu	a1,-64(s0)
    80003d36:	00092503          	lw	a0,0(s2)
    80003d3a:	fffff097          	auipc	ra,0xfffff
    80003d3e:	750080e7          	jalr	1872(ra) # 8000348a <iget>
    80003d42:	a011                	j	80003d46 <dirlookup+0xa0>
  return 0;
    80003d44:	4501                	li	a0,0
}
    80003d46:	70e2                	ld	ra,56(sp)
    80003d48:	7442                	ld	s0,48(sp)
    80003d4a:	74a2                	ld	s1,40(sp)
    80003d4c:	7902                	ld	s2,32(sp)
    80003d4e:	69e2                	ld	s3,24(sp)
    80003d50:	6a42                	ld	s4,16(sp)
    80003d52:	6121                	addi	sp,sp,64
    80003d54:	8082                	ret

0000000080003d56 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d56:	711d                	addi	sp,sp,-96
    80003d58:	ec86                	sd	ra,88(sp)
    80003d5a:	e8a2                	sd	s0,80(sp)
    80003d5c:	e4a6                	sd	s1,72(sp)
    80003d5e:	e0ca                	sd	s2,64(sp)
    80003d60:	fc4e                	sd	s3,56(sp)
    80003d62:	f852                	sd	s4,48(sp)
    80003d64:	f456                	sd	s5,40(sp)
    80003d66:	f05a                	sd	s6,32(sp)
    80003d68:	ec5e                	sd	s7,24(sp)
    80003d6a:	e862                	sd	s8,16(sp)
    80003d6c:	e466                	sd	s9,8(sp)
    80003d6e:	1080                	addi	s0,sp,96
    80003d70:	84aa                	mv	s1,a0
    80003d72:	8b2e                	mv	s6,a1
    80003d74:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d76:	00054703          	lbu	a4,0(a0)
    80003d7a:	02f00793          	li	a5,47
    80003d7e:	02f70363          	beq	a4,a5,80003da4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d82:	ffffe097          	auipc	ra,0xffffe
    80003d86:	c44080e7          	jalr	-956(ra) # 800019c6 <myproc>
    80003d8a:	16053503          	ld	a0,352(a0)
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	9f6080e7          	jalr	-1546(ra) # 80003784 <idup>
    80003d96:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d98:	02f00913          	li	s2,47
  len = path - s;
    80003d9c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d9e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003da0:	4c05                	li	s8,1
    80003da2:	a865                	j	80003e5a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003da4:	4585                	li	a1,1
    80003da6:	4505                	li	a0,1
    80003da8:	fffff097          	auipc	ra,0xfffff
    80003dac:	6e2080e7          	jalr	1762(ra) # 8000348a <iget>
    80003db0:	89aa                	mv	s3,a0
    80003db2:	b7dd                	j	80003d98 <namex+0x42>
      iunlockput(ip);
    80003db4:	854e                	mv	a0,s3
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	c6e080e7          	jalr	-914(ra) # 80003a24 <iunlockput>
      return 0;
    80003dbe:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	60e6                	ld	ra,88(sp)
    80003dc4:	6446                	ld	s0,80(sp)
    80003dc6:	64a6                	ld	s1,72(sp)
    80003dc8:	6906                	ld	s2,64(sp)
    80003dca:	79e2                	ld	s3,56(sp)
    80003dcc:	7a42                	ld	s4,48(sp)
    80003dce:	7aa2                	ld	s5,40(sp)
    80003dd0:	7b02                	ld	s6,32(sp)
    80003dd2:	6be2                	ld	s7,24(sp)
    80003dd4:	6c42                	ld	s8,16(sp)
    80003dd6:	6ca2                	ld	s9,8(sp)
    80003dd8:	6125                	addi	sp,sp,96
    80003dda:	8082                	ret
      iunlock(ip);
    80003ddc:	854e                	mv	a0,s3
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	aa6080e7          	jalr	-1370(ra) # 80003884 <iunlock>
      return ip;
    80003de6:	bfe9                	j	80003dc0 <namex+0x6a>
      iunlockput(ip);
    80003de8:	854e                	mv	a0,s3
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	c3a080e7          	jalr	-966(ra) # 80003a24 <iunlockput>
      return 0;
    80003df2:	89d2                	mv	s3,s4
    80003df4:	b7f1                	j	80003dc0 <namex+0x6a>
  len = path - s;
    80003df6:	40b48633          	sub	a2,s1,a1
    80003dfa:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dfe:	094cd463          	bge	s9,s4,80003e86 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e02:	4639                	li	a2,14
    80003e04:	8556                	mv	a0,s5
    80003e06:	ffffd097          	auipc	ra,0xffffd
    80003e0a:	f40080e7          	jalr	-192(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	01279763          	bne	a5,s2,80003e20 <namex+0xca>
    path++;
    80003e16:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e18:	0004c783          	lbu	a5,0(s1)
    80003e1c:	ff278de3          	beq	a5,s2,80003e16 <namex+0xc0>
    ilock(ip);
    80003e20:	854e                	mv	a0,s3
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	9a0080e7          	jalr	-1632(ra) # 800037c2 <ilock>
    if(ip->type != T_DIR){
    80003e2a:	04499783          	lh	a5,68(s3)
    80003e2e:	f98793e3          	bne	a5,s8,80003db4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e32:	000b0563          	beqz	s6,80003e3c <namex+0xe6>
    80003e36:	0004c783          	lbu	a5,0(s1)
    80003e3a:	d3cd                	beqz	a5,80003ddc <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e3c:	865e                	mv	a2,s7
    80003e3e:	85d6                	mv	a1,s5
    80003e40:	854e                	mv	a0,s3
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	e64080e7          	jalr	-412(ra) # 80003ca6 <dirlookup>
    80003e4a:	8a2a                	mv	s4,a0
    80003e4c:	dd51                	beqz	a0,80003de8 <namex+0x92>
    iunlockput(ip);
    80003e4e:	854e                	mv	a0,s3
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	bd4080e7          	jalr	-1068(ra) # 80003a24 <iunlockput>
    ip = next;
    80003e58:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e5a:	0004c783          	lbu	a5,0(s1)
    80003e5e:	05279763          	bne	a5,s2,80003eac <namex+0x156>
    path++;
    80003e62:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e64:	0004c783          	lbu	a5,0(s1)
    80003e68:	ff278de3          	beq	a5,s2,80003e62 <namex+0x10c>
  if(*path == 0)
    80003e6c:	c79d                	beqz	a5,80003e9a <namex+0x144>
    path++;
    80003e6e:	85a6                	mv	a1,s1
  len = path - s;
    80003e70:	8a5e                	mv	s4,s7
    80003e72:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e74:	01278963          	beq	a5,s2,80003e86 <namex+0x130>
    80003e78:	dfbd                	beqz	a5,80003df6 <namex+0xa0>
    path++;
    80003e7a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e7c:	0004c783          	lbu	a5,0(s1)
    80003e80:	ff279ce3          	bne	a5,s2,80003e78 <namex+0x122>
    80003e84:	bf8d                	j	80003df6 <namex+0xa0>
    memmove(name, s, len);
    80003e86:	2601                	sext.w	a2,a2
    80003e88:	8556                	mv	a0,s5
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	ebc080e7          	jalr	-324(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003e92:	9a56                	add	s4,s4,s5
    80003e94:	000a0023          	sb	zero,0(s4)
    80003e98:	bf9d                	j	80003e0e <namex+0xb8>
  if(nameiparent){
    80003e9a:	f20b03e3          	beqz	s6,80003dc0 <namex+0x6a>
    iput(ip);
    80003e9e:	854e                	mv	a0,s3
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	adc080e7          	jalr	-1316(ra) # 8000397c <iput>
    return 0;
    80003ea8:	4981                	li	s3,0
    80003eaa:	bf19                	j	80003dc0 <namex+0x6a>
  if(*path == 0)
    80003eac:	d7fd                	beqz	a5,80003e9a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003eae:	0004c783          	lbu	a5,0(s1)
    80003eb2:	85a6                	mv	a1,s1
    80003eb4:	b7d1                	j	80003e78 <namex+0x122>

0000000080003eb6 <dirlink>:
{
    80003eb6:	7139                	addi	sp,sp,-64
    80003eb8:	fc06                	sd	ra,56(sp)
    80003eba:	f822                	sd	s0,48(sp)
    80003ebc:	f426                	sd	s1,40(sp)
    80003ebe:	f04a                	sd	s2,32(sp)
    80003ec0:	ec4e                	sd	s3,24(sp)
    80003ec2:	e852                	sd	s4,16(sp)
    80003ec4:	0080                	addi	s0,sp,64
    80003ec6:	892a                	mv	s2,a0
    80003ec8:	8a2e                	mv	s4,a1
    80003eca:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ecc:	4601                	li	a2,0
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	dd8080e7          	jalr	-552(ra) # 80003ca6 <dirlookup>
    80003ed6:	e93d                	bnez	a0,80003f4c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed8:	04c92483          	lw	s1,76(s2)
    80003edc:	c49d                	beqz	s1,80003f0a <dirlink+0x54>
    80003ede:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee0:	4741                	li	a4,16
    80003ee2:	86a6                	mv	a3,s1
    80003ee4:	fc040613          	addi	a2,s0,-64
    80003ee8:	4581                	li	a1,0
    80003eea:	854a                	mv	a0,s2
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	b8a080e7          	jalr	-1142(ra) # 80003a76 <readi>
    80003ef4:	47c1                	li	a5,16
    80003ef6:	06f51163          	bne	a0,a5,80003f58 <dirlink+0xa2>
    if(de.inum == 0)
    80003efa:	fc045783          	lhu	a5,-64(s0)
    80003efe:	c791                	beqz	a5,80003f0a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f00:	24c1                	addiw	s1,s1,16
    80003f02:	04c92783          	lw	a5,76(s2)
    80003f06:	fcf4ede3          	bltu	s1,a5,80003ee0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f0a:	4639                	li	a2,14
    80003f0c:	85d2                	mv	a1,s4
    80003f0e:	fc240513          	addi	a0,s0,-62
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	ee8080e7          	jalr	-280(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003f1a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f1e:	4741                	li	a4,16
    80003f20:	86a6                	mv	a3,s1
    80003f22:	fc040613          	addi	a2,s0,-64
    80003f26:	4581                	li	a1,0
    80003f28:	854a                	mv	a0,s2
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	c44080e7          	jalr	-956(ra) # 80003b6e <writei>
    80003f32:	1541                	addi	a0,a0,-16
    80003f34:	00a03533          	snez	a0,a0
    80003f38:	40a00533          	neg	a0,a0
}
    80003f3c:	70e2                	ld	ra,56(sp)
    80003f3e:	7442                	ld	s0,48(sp)
    80003f40:	74a2                	ld	s1,40(sp)
    80003f42:	7902                	ld	s2,32(sp)
    80003f44:	69e2                	ld	s3,24(sp)
    80003f46:	6a42                	ld	s4,16(sp)
    80003f48:	6121                	addi	sp,sp,64
    80003f4a:	8082                	ret
    iput(ip);
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	a30080e7          	jalr	-1488(ra) # 8000397c <iput>
    return -1;
    80003f54:	557d                	li	a0,-1
    80003f56:	b7dd                	j	80003f3c <dirlink+0x86>
      panic("dirlink read");
    80003f58:	00004517          	auipc	a0,0x4
    80003f5c:	6f050513          	addi	a0,a0,1776 # 80008648 <syscalls+0x1d8>
    80003f60:	ffffc097          	auipc	ra,0xffffc
    80003f64:	5e4080e7          	jalr	1508(ra) # 80000544 <panic>

0000000080003f68 <namei>:

struct inode*
namei(char *path)
{
    80003f68:	1101                	addi	sp,sp,-32
    80003f6a:	ec06                	sd	ra,24(sp)
    80003f6c:	e822                	sd	s0,16(sp)
    80003f6e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f70:	fe040613          	addi	a2,s0,-32
    80003f74:	4581                	li	a1,0
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	de0080e7          	jalr	-544(ra) # 80003d56 <namex>
}
    80003f7e:	60e2                	ld	ra,24(sp)
    80003f80:	6442                	ld	s0,16(sp)
    80003f82:	6105                	addi	sp,sp,32
    80003f84:	8082                	ret

0000000080003f86 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f86:	1141                	addi	sp,sp,-16
    80003f88:	e406                	sd	ra,8(sp)
    80003f8a:	e022                	sd	s0,0(sp)
    80003f8c:	0800                	addi	s0,sp,16
    80003f8e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f90:	4585                	li	a1,1
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	dc4080e7          	jalr	-572(ra) # 80003d56 <namex>
}
    80003f9a:	60a2                	ld	ra,8(sp)
    80003f9c:	6402                	ld	s0,0(sp)
    80003f9e:	0141                	addi	sp,sp,16
    80003fa0:	8082                	ret

0000000080003fa2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fa2:	1101                	addi	sp,sp,-32
    80003fa4:	ec06                	sd	ra,24(sp)
    80003fa6:	e822                	sd	s0,16(sp)
    80003fa8:	e426                	sd	s1,8(sp)
    80003faa:	e04a                	sd	s2,0(sp)
    80003fac:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fae:	0001d917          	auipc	s2,0x1d
    80003fb2:	fa290913          	addi	s2,s2,-94 # 80020f50 <log>
    80003fb6:	01892583          	lw	a1,24(s2)
    80003fba:	02892503          	lw	a0,40(s2)
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	fea080e7          	jalr	-22(ra) # 80002fa8 <bread>
    80003fc6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fc8:	02c92683          	lw	a3,44(s2)
    80003fcc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fce:	02d05763          	blez	a3,80003ffc <write_head+0x5a>
    80003fd2:	0001d797          	auipc	a5,0x1d
    80003fd6:	fae78793          	addi	a5,a5,-82 # 80020f80 <log+0x30>
    80003fda:	05c50713          	addi	a4,a0,92
    80003fde:	36fd                	addiw	a3,a3,-1
    80003fe0:	1682                	slli	a3,a3,0x20
    80003fe2:	9281                	srli	a3,a3,0x20
    80003fe4:	068a                	slli	a3,a3,0x2
    80003fe6:	0001d617          	auipc	a2,0x1d
    80003fea:	f9e60613          	addi	a2,a2,-98 # 80020f84 <log+0x34>
    80003fee:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ff0:	4390                	lw	a2,0(a5)
    80003ff2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ff4:	0791                	addi	a5,a5,4
    80003ff6:	0711                	addi	a4,a4,4
    80003ff8:	fed79ce3          	bne	a5,a3,80003ff0 <write_head+0x4e>
  }
  bwrite(buf);
    80003ffc:	8526                	mv	a0,s1
    80003ffe:	fffff097          	auipc	ra,0xfffff
    80004002:	09c080e7          	jalr	156(ra) # 8000309a <bwrite>
  brelse(buf);
    80004006:	8526                	mv	a0,s1
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	0d0080e7          	jalr	208(ra) # 800030d8 <brelse>
}
    80004010:	60e2                	ld	ra,24(sp)
    80004012:	6442                	ld	s0,16(sp)
    80004014:	64a2                	ld	s1,8(sp)
    80004016:	6902                	ld	s2,0(sp)
    80004018:	6105                	addi	sp,sp,32
    8000401a:	8082                	ret

000000008000401c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000401c:	0001d797          	auipc	a5,0x1d
    80004020:	f607a783          	lw	a5,-160(a5) # 80020f7c <log+0x2c>
    80004024:	0af05d63          	blez	a5,800040de <install_trans+0xc2>
{
    80004028:	7139                	addi	sp,sp,-64
    8000402a:	fc06                	sd	ra,56(sp)
    8000402c:	f822                	sd	s0,48(sp)
    8000402e:	f426                	sd	s1,40(sp)
    80004030:	f04a                	sd	s2,32(sp)
    80004032:	ec4e                	sd	s3,24(sp)
    80004034:	e852                	sd	s4,16(sp)
    80004036:	e456                	sd	s5,8(sp)
    80004038:	e05a                	sd	s6,0(sp)
    8000403a:	0080                	addi	s0,sp,64
    8000403c:	8b2a                	mv	s6,a0
    8000403e:	0001da97          	auipc	s5,0x1d
    80004042:	f42a8a93          	addi	s5,s5,-190 # 80020f80 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004046:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004048:	0001d997          	auipc	s3,0x1d
    8000404c:	f0898993          	addi	s3,s3,-248 # 80020f50 <log>
    80004050:	a035                	j	8000407c <install_trans+0x60>
      bunpin(dbuf);
    80004052:	8526                	mv	a0,s1
    80004054:	fffff097          	auipc	ra,0xfffff
    80004058:	15e080e7          	jalr	350(ra) # 800031b2 <bunpin>
    brelse(lbuf);
    8000405c:	854a                	mv	a0,s2
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	07a080e7          	jalr	122(ra) # 800030d8 <brelse>
    brelse(dbuf);
    80004066:	8526                	mv	a0,s1
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	070080e7          	jalr	112(ra) # 800030d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004070:	2a05                	addiw	s4,s4,1
    80004072:	0a91                	addi	s5,s5,4
    80004074:	02c9a783          	lw	a5,44(s3)
    80004078:	04fa5963          	bge	s4,a5,800040ca <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000407c:	0189a583          	lw	a1,24(s3)
    80004080:	014585bb          	addw	a1,a1,s4
    80004084:	2585                	addiw	a1,a1,1
    80004086:	0289a503          	lw	a0,40(s3)
    8000408a:	fffff097          	auipc	ra,0xfffff
    8000408e:	f1e080e7          	jalr	-226(ra) # 80002fa8 <bread>
    80004092:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004094:	000aa583          	lw	a1,0(s5)
    80004098:	0289a503          	lw	a0,40(s3)
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	f0c080e7          	jalr	-244(ra) # 80002fa8 <bread>
    800040a4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040a6:	40000613          	li	a2,1024
    800040aa:	05890593          	addi	a1,s2,88
    800040ae:	05850513          	addi	a0,a0,88
    800040b2:	ffffd097          	auipc	ra,0xffffd
    800040b6:	c94080e7          	jalr	-876(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040ba:	8526                	mv	a0,s1
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	fde080e7          	jalr	-34(ra) # 8000309a <bwrite>
    if(recovering == 0)
    800040c4:	f80b1ce3          	bnez	s6,8000405c <install_trans+0x40>
    800040c8:	b769                	j	80004052 <install_trans+0x36>
}
    800040ca:	70e2                	ld	ra,56(sp)
    800040cc:	7442                	ld	s0,48(sp)
    800040ce:	74a2                	ld	s1,40(sp)
    800040d0:	7902                	ld	s2,32(sp)
    800040d2:	69e2                	ld	s3,24(sp)
    800040d4:	6a42                	ld	s4,16(sp)
    800040d6:	6aa2                	ld	s5,8(sp)
    800040d8:	6b02                	ld	s6,0(sp)
    800040da:	6121                	addi	sp,sp,64
    800040dc:	8082                	ret
    800040de:	8082                	ret

00000000800040e0 <initlog>:
{
    800040e0:	7179                	addi	sp,sp,-48
    800040e2:	f406                	sd	ra,40(sp)
    800040e4:	f022                	sd	s0,32(sp)
    800040e6:	ec26                	sd	s1,24(sp)
    800040e8:	e84a                	sd	s2,16(sp)
    800040ea:	e44e                	sd	s3,8(sp)
    800040ec:	1800                	addi	s0,sp,48
    800040ee:	892a                	mv	s2,a0
    800040f0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040f2:	0001d497          	auipc	s1,0x1d
    800040f6:	e5e48493          	addi	s1,s1,-418 # 80020f50 <log>
    800040fa:	00004597          	auipc	a1,0x4
    800040fe:	55e58593          	addi	a1,a1,1374 # 80008658 <syscalls+0x1e8>
    80004102:	8526                	mv	a0,s1
    80004104:	ffffd097          	auipc	ra,0xffffd
    80004108:	a56080e7          	jalr	-1450(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    8000410c:	0149a583          	lw	a1,20(s3)
    80004110:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004112:	0109a783          	lw	a5,16(s3)
    80004116:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004118:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000411c:	854a                	mv	a0,s2
    8000411e:	fffff097          	auipc	ra,0xfffff
    80004122:	e8a080e7          	jalr	-374(ra) # 80002fa8 <bread>
  log.lh.n = lh->n;
    80004126:	4d3c                	lw	a5,88(a0)
    80004128:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000412a:	02f05563          	blez	a5,80004154 <initlog+0x74>
    8000412e:	05c50713          	addi	a4,a0,92
    80004132:	0001d697          	auipc	a3,0x1d
    80004136:	e4e68693          	addi	a3,a3,-434 # 80020f80 <log+0x30>
    8000413a:	37fd                	addiw	a5,a5,-1
    8000413c:	1782                	slli	a5,a5,0x20
    8000413e:	9381                	srli	a5,a5,0x20
    80004140:	078a                	slli	a5,a5,0x2
    80004142:	06050613          	addi	a2,a0,96
    80004146:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004148:	4310                	lw	a2,0(a4)
    8000414a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000414c:	0711                	addi	a4,a4,4
    8000414e:	0691                	addi	a3,a3,4
    80004150:	fef71ce3          	bne	a4,a5,80004148 <initlog+0x68>
  brelse(buf);
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	f84080e7          	jalr	-124(ra) # 800030d8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000415c:	4505                	li	a0,1
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	ebe080e7          	jalr	-322(ra) # 8000401c <install_trans>
  log.lh.n = 0;
    80004166:	0001d797          	auipc	a5,0x1d
    8000416a:	e007ab23          	sw	zero,-490(a5) # 80020f7c <log+0x2c>
  write_head(); // clear the log
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	e34080e7          	jalr	-460(ra) # 80003fa2 <write_head>
}
    80004176:	70a2                	ld	ra,40(sp)
    80004178:	7402                	ld	s0,32(sp)
    8000417a:	64e2                	ld	s1,24(sp)
    8000417c:	6942                	ld	s2,16(sp)
    8000417e:	69a2                	ld	s3,8(sp)
    80004180:	6145                	addi	sp,sp,48
    80004182:	8082                	ret

0000000080004184 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004184:	1101                	addi	sp,sp,-32
    80004186:	ec06                	sd	ra,24(sp)
    80004188:	e822                	sd	s0,16(sp)
    8000418a:	e426                	sd	s1,8(sp)
    8000418c:	e04a                	sd	s2,0(sp)
    8000418e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004190:	0001d517          	auipc	a0,0x1d
    80004194:	dc050513          	addi	a0,a0,-576 # 80020f50 <log>
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	a52080e7          	jalr	-1454(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    800041a0:	0001d497          	auipc	s1,0x1d
    800041a4:	db048493          	addi	s1,s1,-592 # 80020f50 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041a8:	4979                	li	s2,30
    800041aa:	a039                	j	800041b8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041ac:	85a6                	mv	a1,s1
    800041ae:	8526                	mv	a0,s1
    800041b0:	ffffe097          	auipc	ra,0xffffe
    800041b4:	f3c080e7          	jalr	-196(ra) # 800020ec <sleep>
    if(log.committing){
    800041b8:	50dc                	lw	a5,36(s1)
    800041ba:	fbed                	bnez	a5,800041ac <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041bc:	509c                	lw	a5,32(s1)
    800041be:	0017871b          	addiw	a4,a5,1
    800041c2:	0007069b          	sext.w	a3,a4
    800041c6:	0027179b          	slliw	a5,a4,0x2
    800041ca:	9fb9                	addw	a5,a5,a4
    800041cc:	0017979b          	slliw	a5,a5,0x1
    800041d0:	54d8                	lw	a4,44(s1)
    800041d2:	9fb9                	addw	a5,a5,a4
    800041d4:	00f95963          	bge	s2,a5,800041e6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041d8:	85a6                	mv	a1,s1
    800041da:	8526                	mv	a0,s1
    800041dc:	ffffe097          	auipc	ra,0xffffe
    800041e0:	f10080e7          	jalr	-240(ra) # 800020ec <sleep>
    800041e4:	bfd1                	j	800041b8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041e6:	0001d517          	auipc	a0,0x1d
    800041ea:	d6a50513          	addi	a0,a0,-662 # 80020f50 <log>
    800041ee:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041f0:	ffffd097          	auipc	ra,0xffffd
    800041f4:	aae080e7          	jalr	-1362(ra) # 80000c9e <release>
      break;
    }
  }
}
    800041f8:	60e2                	ld	ra,24(sp)
    800041fa:	6442                	ld	s0,16(sp)
    800041fc:	64a2                	ld	s1,8(sp)
    800041fe:	6902                	ld	s2,0(sp)
    80004200:	6105                	addi	sp,sp,32
    80004202:	8082                	ret

0000000080004204 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004204:	7139                	addi	sp,sp,-64
    80004206:	fc06                	sd	ra,56(sp)
    80004208:	f822                	sd	s0,48(sp)
    8000420a:	f426                	sd	s1,40(sp)
    8000420c:	f04a                	sd	s2,32(sp)
    8000420e:	ec4e                	sd	s3,24(sp)
    80004210:	e852                	sd	s4,16(sp)
    80004212:	e456                	sd	s5,8(sp)
    80004214:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004216:	0001d497          	auipc	s1,0x1d
    8000421a:	d3a48493          	addi	s1,s1,-710 # 80020f50 <log>
    8000421e:	8526                	mv	a0,s1
    80004220:	ffffd097          	auipc	ra,0xffffd
    80004224:	9ca080e7          	jalr	-1590(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004228:	509c                	lw	a5,32(s1)
    8000422a:	37fd                	addiw	a5,a5,-1
    8000422c:	0007891b          	sext.w	s2,a5
    80004230:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004232:	50dc                	lw	a5,36(s1)
    80004234:	efb9                	bnez	a5,80004292 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004236:	06091663          	bnez	s2,800042a2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000423a:	0001d497          	auipc	s1,0x1d
    8000423e:	d1648493          	addi	s1,s1,-746 # 80020f50 <log>
    80004242:	4785                	li	a5,1
    80004244:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004246:	8526                	mv	a0,s1
    80004248:	ffffd097          	auipc	ra,0xffffd
    8000424c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004250:	54dc                	lw	a5,44(s1)
    80004252:	06f04763          	bgtz	a5,800042c0 <end_op+0xbc>
    acquire(&log.lock);
    80004256:	0001d497          	auipc	s1,0x1d
    8000425a:	cfa48493          	addi	s1,s1,-774 # 80020f50 <log>
    8000425e:	8526                	mv	a0,s1
    80004260:	ffffd097          	auipc	ra,0xffffd
    80004264:	98a080e7          	jalr	-1654(ra) # 80000bea <acquire>
    log.committing = 0;
    80004268:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000426c:	8526                	mv	a0,s1
    8000426e:	ffffe097          	auipc	ra,0xffffe
    80004272:	ee2080e7          	jalr	-286(ra) # 80002150 <wakeup>
    release(&log.lock);
    80004276:	8526                	mv	a0,s1
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	a26080e7          	jalr	-1498(ra) # 80000c9e <release>
}
    80004280:	70e2                	ld	ra,56(sp)
    80004282:	7442                	ld	s0,48(sp)
    80004284:	74a2                	ld	s1,40(sp)
    80004286:	7902                	ld	s2,32(sp)
    80004288:	69e2                	ld	s3,24(sp)
    8000428a:	6a42                	ld	s4,16(sp)
    8000428c:	6aa2                	ld	s5,8(sp)
    8000428e:	6121                	addi	sp,sp,64
    80004290:	8082                	ret
    panic("log.committing");
    80004292:	00004517          	auipc	a0,0x4
    80004296:	3ce50513          	addi	a0,a0,974 # 80008660 <syscalls+0x1f0>
    8000429a:	ffffc097          	auipc	ra,0xffffc
    8000429e:	2aa080e7          	jalr	682(ra) # 80000544 <panic>
    wakeup(&log);
    800042a2:	0001d497          	auipc	s1,0x1d
    800042a6:	cae48493          	addi	s1,s1,-850 # 80020f50 <log>
    800042aa:	8526                	mv	a0,s1
    800042ac:	ffffe097          	auipc	ra,0xffffe
    800042b0:	ea4080e7          	jalr	-348(ra) # 80002150 <wakeup>
  release(&log.lock);
    800042b4:	8526                	mv	a0,s1
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	9e8080e7          	jalr	-1560(ra) # 80000c9e <release>
  if(do_commit){
    800042be:	b7c9                	j	80004280 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c0:	0001da97          	auipc	s5,0x1d
    800042c4:	cc0a8a93          	addi	s5,s5,-832 # 80020f80 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042c8:	0001da17          	auipc	s4,0x1d
    800042cc:	c88a0a13          	addi	s4,s4,-888 # 80020f50 <log>
    800042d0:	018a2583          	lw	a1,24(s4)
    800042d4:	012585bb          	addw	a1,a1,s2
    800042d8:	2585                	addiw	a1,a1,1
    800042da:	028a2503          	lw	a0,40(s4)
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	cca080e7          	jalr	-822(ra) # 80002fa8 <bread>
    800042e6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042e8:	000aa583          	lw	a1,0(s5)
    800042ec:	028a2503          	lw	a0,40(s4)
    800042f0:	fffff097          	auipc	ra,0xfffff
    800042f4:	cb8080e7          	jalr	-840(ra) # 80002fa8 <bread>
    800042f8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042fa:	40000613          	li	a2,1024
    800042fe:	05850593          	addi	a1,a0,88
    80004302:	05848513          	addi	a0,s1,88
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	a40080e7          	jalr	-1472(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    8000430e:	8526                	mv	a0,s1
    80004310:	fffff097          	auipc	ra,0xfffff
    80004314:	d8a080e7          	jalr	-630(ra) # 8000309a <bwrite>
    brelse(from);
    80004318:	854e                	mv	a0,s3
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	dbe080e7          	jalr	-578(ra) # 800030d8 <brelse>
    brelse(to);
    80004322:	8526                	mv	a0,s1
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	db4080e7          	jalr	-588(ra) # 800030d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000432c:	2905                	addiw	s2,s2,1
    8000432e:	0a91                	addi	s5,s5,4
    80004330:	02ca2783          	lw	a5,44(s4)
    80004334:	f8f94ee3          	blt	s2,a5,800042d0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004338:	00000097          	auipc	ra,0x0
    8000433c:	c6a080e7          	jalr	-918(ra) # 80003fa2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004340:	4501                	li	a0,0
    80004342:	00000097          	auipc	ra,0x0
    80004346:	cda080e7          	jalr	-806(ra) # 8000401c <install_trans>
    log.lh.n = 0;
    8000434a:	0001d797          	auipc	a5,0x1d
    8000434e:	c207a923          	sw	zero,-974(a5) # 80020f7c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004352:	00000097          	auipc	ra,0x0
    80004356:	c50080e7          	jalr	-944(ra) # 80003fa2 <write_head>
    8000435a:	bdf5                	j	80004256 <end_op+0x52>

000000008000435c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000435c:	1101                	addi	sp,sp,-32
    8000435e:	ec06                	sd	ra,24(sp)
    80004360:	e822                	sd	s0,16(sp)
    80004362:	e426                	sd	s1,8(sp)
    80004364:	e04a                	sd	s2,0(sp)
    80004366:	1000                	addi	s0,sp,32
    80004368:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000436a:	0001d917          	auipc	s2,0x1d
    8000436e:	be690913          	addi	s2,s2,-1050 # 80020f50 <log>
    80004372:	854a                	mv	a0,s2
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	876080e7          	jalr	-1930(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000437c:	02c92603          	lw	a2,44(s2)
    80004380:	47f5                	li	a5,29
    80004382:	06c7c563          	blt	a5,a2,800043ec <log_write+0x90>
    80004386:	0001d797          	auipc	a5,0x1d
    8000438a:	be67a783          	lw	a5,-1050(a5) # 80020f6c <log+0x1c>
    8000438e:	37fd                	addiw	a5,a5,-1
    80004390:	04f65e63          	bge	a2,a5,800043ec <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004394:	0001d797          	auipc	a5,0x1d
    80004398:	bdc7a783          	lw	a5,-1060(a5) # 80020f70 <log+0x20>
    8000439c:	06f05063          	blez	a5,800043fc <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043a0:	4781                	li	a5,0
    800043a2:	06c05563          	blez	a2,8000440c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043a6:	44cc                	lw	a1,12(s1)
    800043a8:	0001d717          	auipc	a4,0x1d
    800043ac:	bd870713          	addi	a4,a4,-1064 # 80020f80 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043b0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043b2:	4314                	lw	a3,0(a4)
    800043b4:	04b68c63          	beq	a3,a1,8000440c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043b8:	2785                	addiw	a5,a5,1
    800043ba:	0711                	addi	a4,a4,4
    800043bc:	fef61be3          	bne	a2,a5,800043b2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043c0:	0621                	addi	a2,a2,8
    800043c2:	060a                	slli	a2,a2,0x2
    800043c4:	0001d797          	auipc	a5,0x1d
    800043c8:	b8c78793          	addi	a5,a5,-1140 # 80020f50 <log>
    800043cc:	963e                	add	a2,a2,a5
    800043ce:	44dc                	lw	a5,12(s1)
    800043d0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043d2:	8526                	mv	a0,s1
    800043d4:	fffff097          	auipc	ra,0xfffff
    800043d8:	da2080e7          	jalr	-606(ra) # 80003176 <bpin>
    log.lh.n++;
    800043dc:	0001d717          	auipc	a4,0x1d
    800043e0:	b7470713          	addi	a4,a4,-1164 # 80020f50 <log>
    800043e4:	575c                	lw	a5,44(a4)
    800043e6:	2785                	addiw	a5,a5,1
    800043e8:	d75c                	sw	a5,44(a4)
    800043ea:	a835                	j	80004426 <log_write+0xca>
    panic("too big a transaction");
    800043ec:	00004517          	auipc	a0,0x4
    800043f0:	28450513          	addi	a0,a0,644 # 80008670 <syscalls+0x200>
    800043f4:	ffffc097          	auipc	ra,0xffffc
    800043f8:	150080e7          	jalr	336(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800043fc:	00004517          	auipc	a0,0x4
    80004400:	28c50513          	addi	a0,a0,652 # 80008688 <syscalls+0x218>
    80004404:	ffffc097          	auipc	ra,0xffffc
    80004408:	140080e7          	jalr	320(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    8000440c:	00878713          	addi	a4,a5,8
    80004410:	00271693          	slli	a3,a4,0x2
    80004414:	0001d717          	auipc	a4,0x1d
    80004418:	b3c70713          	addi	a4,a4,-1220 # 80020f50 <log>
    8000441c:	9736                	add	a4,a4,a3
    8000441e:	44d4                	lw	a3,12(s1)
    80004420:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004422:	faf608e3          	beq	a2,a5,800043d2 <log_write+0x76>
  }
  release(&log.lock);
    80004426:	0001d517          	auipc	a0,0x1d
    8000442a:	b2a50513          	addi	a0,a0,-1238 # 80020f50 <log>
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	870080e7          	jalr	-1936(ra) # 80000c9e <release>
}
    80004436:	60e2                	ld	ra,24(sp)
    80004438:	6442                	ld	s0,16(sp)
    8000443a:	64a2                	ld	s1,8(sp)
    8000443c:	6902                	ld	s2,0(sp)
    8000443e:	6105                	addi	sp,sp,32
    80004440:	8082                	ret

0000000080004442 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004442:	1101                	addi	sp,sp,-32
    80004444:	ec06                	sd	ra,24(sp)
    80004446:	e822                	sd	s0,16(sp)
    80004448:	e426                	sd	s1,8(sp)
    8000444a:	e04a                	sd	s2,0(sp)
    8000444c:	1000                	addi	s0,sp,32
    8000444e:	84aa                	mv	s1,a0
    80004450:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004452:	00004597          	auipc	a1,0x4
    80004456:	25658593          	addi	a1,a1,598 # 800086a8 <syscalls+0x238>
    8000445a:	0521                	addi	a0,a0,8
    8000445c:	ffffc097          	auipc	ra,0xffffc
    80004460:	6fe080e7          	jalr	1790(ra) # 80000b5a <initlock>
  lk->name = name;
    80004464:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004468:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000446c:	0204a423          	sw	zero,40(s1)
}
    80004470:	60e2                	ld	ra,24(sp)
    80004472:	6442                	ld	s0,16(sp)
    80004474:	64a2                	ld	s1,8(sp)
    80004476:	6902                	ld	s2,0(sp)
    80004478:	6105                	addi	sp,sp,32
    8000447a:	8082                	ret

000000008000447c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000447c:	1101                	addi	sp,sp,-32
    8000447e:	ec06                	sd	ra,24(sp)
    80004480:	e822                	sd	s0,16(sp)
    80004482:	e426                	sd	s1,8(sp)
    80004484:	e04a                	sd	s2,0(sp)
    80004486:	1000                	addi	s0,sp,32
    80004488:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000448a:	00850913          	addi	s2,a0,8
    8000448e:	854a                	mv	a0,s2
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	75a080e7          	jalr	1882(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004498:	409c                	lw	a5,0(s1)
    8000449a:	cb89                	beqz	a5,800044ac <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000449c:	85ca                	mv	a1,s2
    8000449e:	8526                	mv	a0,s1
    800044a0:	ffffe097          	auipc	ra,0xffffe
    800044a4:	c4c080e7          	jalr	-948(ra) # 800020ec <sleep>
  while (lk->locked) {
    800044a8:	409c                	lw	a5,0(s1)
    800044aa:	fbed                	bnez	a5,8000449c <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044ac:	4785                	li	a5,1
    800044ae:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044b0:	ffffd097          	auipc	ra,0xffffd
    800044b4:	516080e7          	jalr	1302(ra) # 800019c6 <myproc>
    800044b8:	591c                	lw	a5,48(a0)
    800044ba:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044bc:	854a                	mv	a0,s2
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	7e0080e7          	jalr	2016(ra) # 80000c9e <release>
}
    800044c6:	60e2                	ld	ra,24(sp)
    800044c8:	6442                	ld	s0,16(sp)
    800044ca:	64a2                	ld	s1,8(sp)
    800044cc:	6902                	ld	s2,0(sp)
    800044ce:	6105                	addi	sp,sp,32
    800044d0:	8082                	ret

00000000800044d2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044d2:	1101                	addi	sp,sp,-32
    800044d4:	ec06                	sd	ra,24(sp)
    800044d6:	e822                	sd	s0,16(sp)
    800044d8:	e426                	sd	s1,8(sp)
    800044da:	e04a                	sd	s2,0(sp)
    800044dc:	1000                	addi	s0,sp,32
    800044de:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e0:	00850913          	addi	s2,a0,8
    800044e4:	854a                	mv	a0,s2
    800044e6:	ffffc097          	auipc	ra,0xffffc
    800044ea:	704080e7          	jalr	1796(ra) # 80000bea <acquire>
  lk->locked = 0;
    800044ee:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044f2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044f6:	8526                	mv	a0,s1
    800044f8:	ffffe097          	auipc	ra,0xffffe
    800044fc:	c58080e7          	jalr	-936(ra) # 80002150 <wakeup>
  release(&lk->lk);
    80004500:	854a                	mv	a0,s2
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	79c080e7          	jalr	1948(ra) # 80000c9e <release>
}
    8000450a:	60e2                	ld	ra,24(sp)
    8000450c:	6442                	ld	s0,16(sp)
    8000450e:	64a2                	ld	s1,8(sp)
    80004510:	6902                	ld	s2,0(sp)
    80004512:	6105                	addi	sp,sp,32
    80004514:	8082                	ret

0000000080004516 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004516:	7179                	addi	sp,sp,-48
    80004518:	f406                	sd	ra,40(sp)
    8000451a:	f022                	sd	s0,32(sp)
    8000451c:	ec26                	sd	s1,24(sp)
    8000451e:	e84a                	sd	s2,16(sp)
    80004520:	e44e                	sd	s3,8(sp)
    80004522:	1800                	addi	s0,sp,48
    80004524:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004526:	00850913          	addi	s2,a0,8
    8000452a:	854a                	mv	a0,s2
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	6be080e7          	jalr	1726(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004534:	409c                	lw	a5,0(s1)
    80004536:	ef99                	bnez	a5,80004554 <holdingsleep+0x3e>
    80004538:	4481                	li	s1,0
  release(&lk->lk);
    8000453a:	854a                	mv	a0,s2
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	762080e7          	jalr	1890(ra) # 80000c9e <release>
  return r;
}
    80004544:	8526                	mv	a0,s1
    80004546:	70a2                	ld	ra,40(sp)
    80004548:	7402                	ld	s0,32(sp)
    8000454a:	64e2                	ld	s1,24(sp)
    8000454c:	6942                	ld	s2,16(sp)
    8000454e:	69a2                	ld	s3,8(sp)
    80004550:	6145                	addi	sp,sp,48
    80004552:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004554:	0284a983          	lw	s3,40(s1)
    80004558:	ffffd097          	auipc	ra,0xffffd
    8000455c:	46e080e7          	jalr	1134(ra) # 800019c6 <myproc>
    80004560:	5904                	lw	s1,48(a0)
    80004562:	413484b3          	sub	s1,s1,s3
    80004566:	0014b493          	seqz	s1,s1
    8000456a:	bfc1                	j	8000453a <holdingsleep+0x24>

000000008000456c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000456c:	1141                	addi	sp,sp,-16
    8000456e:	e406                	sd	ra,8(sp)
    80004570:	e022                	sd	s0,0(sp)
    80004572:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004574:	00004597          	auipc	a1,0x4
    80004578:	14458593          	addi	a1,a1,324 # 800086b8 <syscalls+0x248>
    8000457c:	0001d517          	auipc	a0,0x1d
    80004580:	b1c50513          	addi	a0,a0,-1252 # 80021098 <ftable>
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	5d6080e7          	jalr	1494(ra) # 80000b5a <initlock>
}
    8000458c:	60a2                	ld	ra,8(sp)
    8000458e:	6402                	ld	s0,0(sp)
    80004590:	0141                	addi	sp,sp,16
    80004592:	8082                	ret

0000000080004594 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004594:	1101                	addi	sp,sp,-32
    80004596:	ec06                	sd	ra,24(sp)
    80004598:	e822                	sd	s0,16(sp)
    8000459a:	e426                	sd	s1,8(sp)
    8000459c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000459e:	0001d517          	auipc	a0,0x1d
    800045a2:	afa50513          	addi	a0,a0,-1286 # 80021098 <ftable>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	644080e7          	jalr	1604(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ae:	0001d497          	auipc	s1,0x1d
    800045b2:	b0248493          	addi	s1,s1,-1278 # 800210b0 <ftable+0x18>
    800045b6:	0001e717          	auipc	a4,0x1e
    800045ba:	a9a70713          	addi	a4,a4,-1382 # 80022050 <disk>
    if(f->ref == 0){
    800045be:	40dc                	lw	a5,4(s1)
    800045c0:	cf99                	beqz	a5,800045de <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045c2:	02848493          	addi	s1,s1,40
    800045c6:	fee49ce3          	bne	s1,a4,800045be <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045ca:	0001d517          	auipc	a0,0x1d
    800045ce:	ace50513          	addi	a0,a0,-1330 # 80021098 <ftable>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	6cc080e7          	jalr	1740(ra) # 80000c9e <release>
  return 0;
    800045da:	4481                	li	s1,0
    800045dc:	a819                	j	800045f2 <filealloc+0x5e>
      f->ref = 1;
    800045de:	4785                	li	a5,1
    800045e0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045e2:	0001d517          	auipc	a0,0x1d
    800045e6:	ab650513          	addi	a0,a0,-1354 # 80021098 <ftable>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	6b4080e7          	jalr	1716(ra) # 80000c9e <release>
}
    800045f2:	8526                	mv	a0,s1
    800045f4:	60e2                	ld	ra,24(sp)
    800045f6:	6442                	ld	s0,16(sp)
    800045f8:	64a2                	ld	s1,8(sp)
    800045fa:	6105                	addi	sp,sp,32
    800045fc:	8082                	ret

00000000800045fe <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045fe:	1101                	addi	sp,sp,-32
    80004600:	ec06                	sd	ra,24(sp)
    80004602:	e822                	sd	s0,16(sp)
    80004604:	e426                	sd	s1,8(sp)
    80004606:	1000                	addi	s0,sp,32
    80004608:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000460a:	0001d517          	auipc	a0,0x1d
    8000460e:	a8e50513          	addi	a0,a0,-1394 # 80021098 <ftable>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	5d8080e7          	jalr	1496(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000461a:	40dc                	lw	a5,4(s1)
    8000461c:	02f05263          	blez	a5,80004640 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004620:	2785                	addiw	a5,a5,1
    80004622:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004624:	0001d517          	auipc	a0,0x1d
    80004628:	a7450513          	addi	a0,a0,-1420 # 80021098 <ftable>
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	672080e7          	jalr	1650(ra) # 80000c9e <release>
  return f;
}
    80004634:	8526                	mv	a0,s1
    80004636:	60e2                	ld	ra,24(sp)
    80004638:	6442                	ld	s0,16(sp)
    8000463a:	64a2                	ld	s1,8(sp)
    8000463c:	6105                	addi	sp,sp,32
    8000463e:	8082                	ret
    panic("filedup");
    80004640:	00004517          	auipc	a0,0x4
    80004644:	08050513          	addi	a0,a0,128 # 800086c0 <syscalls+0x250>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	efc080e7          	jalr	-260(ra) # 80000544 <panic>

0000000080004650 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004650:	7139                	addi	sp,sp,-64
    80004652:	fc06                	sd	ra,56(sp)
    80004654:	f822                	sd	s0,48(sp)
    80004656:	f426                	sd	s1,40(sp)
    80004658:	f04a                	sd	s2,32(sp)
    8000465a:	ec4e                	sd	s3,24(sp)
    8000465c:	e852                	sd	s4,16(sp)
    8000465e:	e456                	sd	s5,8(sp)
    80004660:	0080                	addi	s0,sp,64
    80004662:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004664:	0001d517          	auipc	a0,0x1d
    80004668:	a3450513          	addi	a0,a0,-1484 # 80021098 <ftable>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	57e080e7          	jalr	1406(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004674:	40dc                	lw	a5,4(s1)
    80004676:	06f05163          	blez	a5,800046d8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000467a:	37fd                	addiw	a5,a5,-1
    8000467c:	0007871b          	sext.w	a4,a5
    80004680:	c0dc                	sw	a5,4(s1)
    80004682:	06e04363          	bgtz	a4,800046e8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004686:	0004a903          	lw	s2,0(s1)
    8000468a:	0094ca83          	lbu	s5,9(s1)
    8000468e:	0104ba03          	ld	s4,16(s1)
    80004692:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004696:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000469a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000469e:	0001d517          	auipc	a0,0x1d
    800046a2:	9fa50513          	addi	a0,a0,-1542 # 80021098 <ftable>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	5f8080e7          	jalr	1528(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800046ae:	4785                	li	a5,1
    800046b0:	04f90d63          	beq	s2,a5,8000470a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046b4:	3979                	addiw	s2,s2,-2
    800046b6:	4785                	li	a5,1
    800046b8:	0527e063          	bltu	a5,s2,800046f8 <fileclose+0xa8>
    begin_op();
    800046bc:	00000097          	auipc	ra,0x0
    800046c0:	ac8080e7          	jalr	-1336(ra) # 80004184 <begin_op>
    iput(ff.ip);
    800046c4:	854e                	mv	a0,s3
    800046c6:	fffff097          	auipc	ra,0xfffff
    800046ca:	2b6080e7          	jalr	694(ra) # 8000397c <iput>
    end_op();
    800046ce:	00000097          	auipc	ra,0x0
    800046d2:	b36080e7          	jalr	-1226(ra) # 80004204 <end_op>
    800046d6:	a00d                	j	800046f8 <fileclose+0xa8>
    panic("fileclose");
    800046d8:	00004517          	auipc	a0,0x4
    800046dc:	ff050513          	addi	a0,a0,-16 # 800086c8 <syscalls+0x258>
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	e64080e7          	jalr	-412(ra) # 80000544 <panic>
    release(&ftable.lock);
    800046e8:	0001d517          	auipc	a0,0x1d
    800046ec:	9b050513          	addi	a0,a0,-1616 # 80021098 <ftable>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	5ae080e7          	jalr	1454(ra) # 80000c9e <release>
  }
}
    800046f8:	70e2                	ld	ra,56(sp)
    800046fa:	7442                	ld	s0,48(sp)
    800046fc:	74a2                	ld	s1,40(sp)
    800046fe:	7902                	ld	s2,32(sp)
    80004700:	69e2                	ld	s3,24(sp)
    80004702:	6a42                	ld	s4,16(sp)
    80004704:	6aa2                	ld	s5,8(sp)
    80004706:	6121                	addi	sp,sp,64
    80004708:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000470a:	85d6                	mv	a1,s5
    8000470c:	8552                	mv	a0,s4
    8000470e:	00000097          	auipc	ra,0x0
    80004712:	34c080e7          	jalr	844(ra) # 80004a5a <pipeclose>
    80004716:	b7cd                	j	800046f8 <fileclose+0xa8>

0000000080004718 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004718:	715d                	addi	sp,sp,-80
    8000471a:	e486                	sd	ra,72(sp)
    8000471c:	e0a2                	sd	s0,64(sp)
    8000471e:	fc26                	sd	s1,56(sp)
    80004720:	f84a                	sd	s2,48(sp)
    80004722:	f44e                	sd	s3,40(sp)
    80004724:	0880                	addi	s0,sp,80
    80004726:	84aa                	mv	s1,a0
    80004728:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000472a:	ffffd097          	auipc	ra,0xffffd
    8000472e:	29c080e7          	jalr	668(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004732:	409c                	lw	a5,0(s1)
    80004734:	37f9                	addiw	a5,a5,-2
    80004736:	4705                	li	a4,1
    80004738:	04f76763          	bltu	a4,a5,80004786 <filestat+0x6e>
    8000473c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000473e:	6c88                	ld	a0,24(s1)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	082080e7          	jalr	130(ra) # 800037c2 <ilock>
    stati(f->ip, &st);
    80004748:	fb840593          	addi	a1,s0,-72
    8000474c:	6c88                	ld	a0,24(s1)
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	2fe080e7          	jalr	766(ra) # 80003a4c <stati>
    iunlock(f->ip);
    80004756:	6c88                	ld	a0,24(s1)
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	12c080e7          	jalr	300(ra) # 80003884 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004760:	46e1                	li	a3,24
    80004762:	fb840613          	addi	a2,s0,-72
    80004766:	85ce                	mv	a1,s3
    80004768:	06093503          	ld	a0,96(s2)
    8000476c:	ffffd097          	auipc	ra,0xffffd
    80004770:	f18080e7          	jalr	-232(ra) # 80001684 <copyout>
    80004774:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004778:	60a6                	ld	ra,72(sp)
    8000477a:	6406                	ld	s0,64(sp)
    8000477c:	74e2                	ld	s1,56(sp)
    8000477e:	7942                	ld	s2,48(sp)
    80004780:	79a2                	ld	s3,40(sp)
    80004782:	6161                	addi	sp,sp,80
    80004784:	8082                	ret
  return -1;
    80004786:	557d                	li	a0,-1
    80004788:	bfc5                	j	80004778 <filestat+0x60>

000000008000478a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000478a:	7179                	addi	sp,sp,-48
    8000478c:	f406                	sd	ra,40(sp)
    8000478e:	f022                	sd	s0,32(sp)
    80004790:	ec26                	sd	s1,24(sp)
    80004792:	e84a                	sd	s2,16(sp)
    80004794:	e44e                	sd	s3,8(sp)
    80004796:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004798:	00854783          	lbu	a5,8(a0)
    8000479c:	c3d5                	beqz	a5,80004840 <fileread+0xb6>
    8000479e:	84aa                	mv	s1,a0
    800047a0:	89ae                	mv	s3,a1
    800047a2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047a4:	411c                	lw	a5,0(a0)
    800047a6:	4705                	li	a4,1
    800047a8:	04e78963          	beq	a5,a4,800047fa <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ac:	470d                	li	a4,3
    800047ae:	04e78d63          	beq	a5,a4,80004808 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047b2:	4709                	li	a4,2
    800047b4:	06e79e63          	bne	a5,a4,80004830 <fileread+0xa6>
    ilock(f->ip);
    800047b8:	6d08                	ld	a0,24(a0)
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	008080e7          	jalr	8(ra) # 800037c2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047c2:	874a                	mv	a4,s2
    800047c4:	5094                	lw	a3,32(s1)
    800047c6:	864e                	mv	a2,s3
    800047c8:	4585                	li	a1,1
    800047ca:	6c88                	ld	a0,24(s1)
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	2aa080e7          	jalr	682(ra) # 80003a76 <readi>
    800047d4:	892a                	mv	s2,a0
    800047d6:	00a05563          	blez	a0,800047e0 <fileread+0x56>
      f->off += r;
    800047da:	509c                	lw	a5,32(s1)
    800047dc:	9fa9                	addw	a5,a5,a0
    800047de:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047e0:	6c88                	ld	a0,24(s1)
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	0a2080e7          	jalr	162(ra) # 80003884 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047ea:	854a                	mv	a0,s2
    800047ec:	70a2                	ld	ra,40(sp)
    800047ee:	7402                	ld	s0,32(sp)
    800047f0:	64e2                	ld	s1,24(sp)
    800047f2:	6942                	ld	s2,16(sp)
    800047f4:	69a2                	ld	s3,8(sp)
    800047f6:	6145                	addi	sp,sp,48
    800047f8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047fa:	6908                	ld	a0,16(a0)
    800047fc:	00000097          	auipc	ra,0x0
    80004800:	3ce080e7          	jalr	974(ra) # 80004bca <piperead>
    80004804:	892a                	mv	s2,a0
    80004806:	b7d5                	j	800047ea <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004808:	02451783          	lh	a5,36(a0)
    8000480c:	03079693          	slli	a3,a5,0x30
    80004810:	92c1                	srli	a3,a3,0x30
    80004812:	4725                	li	a4,9
    80004814:	02d76863          	bltu	a4,a3,80004844 <fileread+0xba>
    80004818:	0792                	slli	a5,a5,0x4
    8000481a:	0001c717          	auipc	a4,0x1c
    8000481e:	7de70713          	addi	a4,a4,2014 # 80020ff8 <devsw>
    80004822:	97ba                	add	a5,a5,a4
    80004824:	639c                	ld	a5,0(a5)
    80004826:	c38d                	beqz	a5,80004848 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004828:	4505                	li	a0,1
    8000482a:	9782                	jalr	a5
    8000482c:	892a                	mv	s2,a0
    8000482e:	bf75                	j	800047ea <fileread+0x60>
    panic("fileread");
    80004830:	00004517          	auipc	a0,0x4
    80004834:	ea850513          	addi	a0,a0,-344 # 800086d8 <syscalls+0x268>
    80004838:	ffffc097          	auipc	ra,0xffffc
    8000483c:	d0c080e7          	jalr	-756(ra) # 80000544 <panic>
    return -1;
    80004840:	597d                	li	s2,-1
    80004842:	b765                	j	800047ea <fileread+0x60>
      return -1;
    80004844:	597d                	li	s2,-1
    80004846:	b755                	j	800047ea <fileread+0x60>
    80004848:	597d                	li	s2,-1
    8000484a:	b745                	j	800047ea <fileread+0x60>

000000008000484c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000484c:	715d                	addi	sp,sp,-80
    8000484e:	e486                	sd	ra,72(sp)
    80004850:	e0a2                	sd	s0,64(sp)
    80004852:	fc26                	sd	s1,56(sp)
    80004854:	f84a                	sd	s2,48(sp)
    80004856:	f44e                	sd	s3,40(sp)
    80004858:	f052                	sd	s4,32(sp)
    8000485a:	ec56                	sd	s5,24(sp)
    8000485c:	e85a                	sd	s6,16(sp)
    8000485e:	e45e                	sd	s7,8(sp)
    80004860:	e062                	sd	s8,0(sp)
    80004862:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004864:	00954783          	lbu	a5,9(a0)
    80004868:	10078663          	beqz	a5,80004974 <filewrite+0x128>
    8000486c:	892a                	mv	s2,a0
    8000486e:	8aae                	mv	s5,a1
    80004870:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004872:	411c                	lw	a5,0(a0)
    80004874:	4705                	li	a4,1
    80004876:	02e78263          	beq	a5,a4,8000489a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000487a:	470d                	li	a4,3
    8000487c:	02e78663          	beq	a5,a4,800048a8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004880:	4709                	li	a4,2
    80004882:	0ee79163          	bne	a5,a4,80004964 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004886:	0ac05d63          	blez	a2,80004940 <filewrite+0xf4>
    int i = 0;
    8000488a:	4981                	li	s3,0
    8000488c:	6b05                	lui	s6,0x1
    8000488e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004892:	6b85                	lui	s7,0x1
    80004894:	c00b8b9b          	addiw	s7,s7,-1024
    80004898:	a861                	j	80004930 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000489a:	6908                	ld	a0,16(a0)
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	22e080e7          	jalr	558(ra) # 80004aca <pipewrite>
    800048a4:	8a2a                	mv	s4,a0
    800048a6:	a045                	j	80004946 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048a8:	02451783          	lh	a5,36(a0)
    800048ac:	03079693          	slli	a3,a5,0x30
    800048b0:	92c1                	srli	a3,a3,0x30
    800048b2:	4725                	li	a4,9
    800048b4:	0cd76263          	bltu	a4,a3,80004978 <filewrite+0x12c>
    800048b8:	0792                	slli	a5,a5,0x4
    800048ba:	0001c717          	auipc	a4,0x1c
    800048be:	73e70713          	addi	a4,a4,1854 # 80020ff8 <devsw>
    800048c2:	97ba                	add	a5,a5,a4
    800048c4:	679c                	ld	a5,8(a5)
    800048c6:	cbdd                	beqz	a5,8000497c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048c8:	4505                	li	a0,1
    800048ca:	9782                	jalr	a5
    800048cc:	8a2a                	mv	s4,a0
    800048ce:	a8a5                	j	80004946 <filewrite+0xfa>
    800048d0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	8b0080e7          	jalr	-1872(ra) # 80004184 <begin_op>
      ilock(f->ip);
    800048dc:	01893503          	ld	a0,24(s2)
    800048e0:	fffff097          	auipc	ra,0xfffff
    800048e4:	ee2080e7          	jalr	-286(ra) # 800037c2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048e8:	8762                	mv	a4,s8
    800048ea:	02092683          	lw	a3,32(s2)
    800048ee:	01598633          	add	a2,s3,s5
    800048f2:	4585                	li	a1,1
    800048f4:	01893503          	ld	a0,24(s2)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	276080e7          	jalr	630(ra) # 80003b6e <writei>
    80004900:	84aa                	mv	s1,a0
    80004902:	00a05763          	blez	a0,80004910 <filewrite+0xc4>
        f->off += r;
    80004906:	02092783          	lw	a5,32(s2)
    8000490a:	9fa9                	addw	a5,a5,a0
    8000490c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004910:	01893503          	ld	a0,24(s2)
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	f70080e7          	jalr	-144(ra) # 80003884 <iunlock>
      end_op();
    8000491c:	00000097          	auipc	ra,0x0
    80004920:	8e8080e7          	jalr	-1816(ra) # 80004204 <end_op>

      if(r != n1){
    80004924:	009c1f63          	bne	s8,s1,80004942 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004928:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000492c:	0149db63          	bge	s3,s4,80004942 <filewrite+0xf6>
      int n1 = n - i;
    80004930:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004934:	84be                	mv	s1,a5
    80004936:	2781                	sext.w	a5,a5
    80004938:	f8fb5ce3          	bge	s6,a5,800048d0 <filewrite+0x84>
    8000493c:	84de                	mv	s1,s7
    8000493e:	bf49                	j	800048d0 <filewrite+0x84>
    int i = 0;
    80004940:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004942:	013a1f63          	bne	s4,s3,80004960 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004946:	8552                	mv	a0,s4
    80004948:	60a6                	ld	ra,72(sp)
    8000494a:	6406                	ld	s0,64(sp)
    8000494c:	74e2                	ld	s1,56(sp)
    8000494e:	7942                	ld	s2,48(sp)
    80004950:	79a2                	ld	s3,40(sp)
    80004952:	7a02                	ld	s4,32(sp)
    80004954:	6ae2                	ld	s5,24(sp)
    80004956:	6b42                	ld	s6,16(sp)
    80004958:	6ba2                	ld	s7,8(sp)
    8000495a:	6c02                	ld	s8,0(sp)
    8000495c:	6161                	addi	sp,sp,80
    8000495e:	8082                	ret
    ret = (i == n ? n : -1);
    80004960:	5a7d                	li	s4,-1
    80004962:	b7d5                	j	80004946 <filewrite+0xfa>
    panic("filewrite");
    80004964:	00004517          	auipc	a0,0x4
    80004968:	d8450513          	addi	a0,a0,-636 # 800086e8 <syscalls+0x278>
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	bd8080e7          	jalr	-1064(ra) # 80000544 <panic>
    return -1;
    80004974:	5a7d                	li	s4,-1
    80004976:	bfc1                	j	80004946 <filewrite+0xfa>
      return -1;
    80004978:	5a7d                	li	s4,-1
    8000497a:	b7f1                	j	80004946 <filewrite+0xfa>
    8000497c:	5a7d                	li	s4,-1
    8000497e:	b7e1                	j	80004946 <filewrite+0xfa>

0000000080004980 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004980:	7179                	addi	sp,sp,-48
    80004982:	f406                	sd	ra,40(sp)
    80004984:	f022                	sd	s0,32(sp)
    80004986:	ec26                	sd	s1,24(sp)
    80004988:	e84a                	sd	s2,16(sp)
    8000498a:	e44e                	sd	s3,8(sp)
    8000498c:	e052                	sd	s4,0(sp)
    8000498e:	1800                	addi	s0,sp,48
    80004990:	84aa                	mv	s1,a0
    80004992:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004994:	0005b023          	sd	zero,0(a1)
    80004998:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000499c:	00000097          	auipc	ra,0x0
    800049a0:	bf8080e7          	jalr	-1032(ra) # 80004594 <filealloc>
    800049a4:	e088                	sd	a0,0(s1)
    800049a6:	c551                	beqz	a0,80004a32 <pipealloc+0xb2>
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	bec080e7          	jalr	-1044(ra) # 80004594 <filealloc>
    800049b0:	00aa3023          	sd	a0,0(s4)
    800049b4:	c92d                	beqz	a0,80004a26 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	144080e7          	jalr	324(ra) # 80000afa <kalloc>
    800049be:	892a                	mv	s2,a0
    800049c0:	c125                	beqz	a0,80004a20 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049c2:	4985                	li	s3,1
    800049c4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049c8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049cc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049d0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049d4:	00004597          	auipc	a1,0x4
    800049d8:	d2458593          	addi	a1,a1,-732 # 800086f8 <syscalls+0x288>
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	17e080e7          	jalr	382(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800049e4:	609c                	ld	a5,0(s1)
    800049e6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049ea:	609c                	ld	a5,0(s1)
    800049ec:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049f0:	609c                	ld	a5,0(s1)
    800049f2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049f6:	609c                	ld	a5,0(s1)
    800049f8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049fc:	000a3783          	ld	a5,0(s4)
    80004a00:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a04:	000a3783          	ld	a5,0(s4)
    80004a08:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a0c:	000a3783          	ld	a5,0(s4)
    80004a10:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a14:	000a3783          	ld	a5,0(s4)
    80004a18:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a1c:	4501                	li	a0,0
    80004a1e:	a025                	j	80004a46 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a20:	6088                	ld	a0,0(s1)
    80004a22:	e501                	bnez	a0,80004a2a <pipealloc+0xaa>
    80004a24:	a039                	j	80004a32 <pipealloc+0xb2>
    80004a26:	6088                	ld	a0,0(s1)
    80004a28:	c51d                	beqz	a0,80004a56 <pipealloc+0xd6>
    fileclose(*f0);
    80004a2a:	00000097          	auipc	ra,0x0
    80004a2e:	c26080e7          	jalr	-986(ra) # 80004650 <fileclose>
  if(*f1)
    80004a32:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a36:	557d                	li	a0,-1
  if(*f1)
    80004a38:	c799                	beqz	a5,80004a46 <pipealloc+0xc6>
    fileclose(*f1);
    80004a3a:	853e                	mv	a0,a5
    80004a3c:	00000097          	auipc	ra,0x0
    80004a40:	c14080e7          	jalr	-1004(ra) # 80004650 <fileclose>
  return -1;
    80004a44:	557d                	li	a0,-1
}
    80004a46:	70a2                	ld	ra,40(sp)
    80004a48:	7402                	ld	s0,32(sp)
    80004a4a:	64e2                	ld	s1,24(sp)
    80004a4c:	6942                	ld	s2,16(sp)
    80004a4e:	69a2                	ld	s3,8(sp)
    80004a50:	6a02                	ld	s4,0(sp)
    80004a52:	6145                	addi	sp,sp,48
    80004a54:	8082                	ret
  return -1;
    80004a56:	557d                	li	a0,-1
    80004a58:	b7fd                	j	80004a46 <pipealloc+0xc6>

0000000080004a5a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a5a:	1101                	addi	sp,sp,-32
    80004a5c:	ec06                	sd	ra,24(sp)
    80004a5e:	e822                	sd	s0,16(sp)
    80004a60:	e426                	sd	s1,8(sp)
    80004a62:	e04a                	sd	s2,0(sp)
    80004a64:	1000                	addi	s0,sp,32
    80004a66:	84aa                	mv	s1,a0
    80004a68:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	180080e7          	jalr	384(ra) # 80000bea <acquire>
  if(writable){
    80004a72:	02090d63          	beqz	s2,80004aac <pipeclose+0x52>
    pi->writeopen = 0;
    80004a76:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a7a:	21848513          	addi	a0,s1,536
    80004a7e:	ffffd097          	auipc	ra,0xffffd
    80004a82:	6d2080e7          	jalr	1746(ra) # 80002150 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a86:	2204b783          	ld	a5,544(s1)
    80004a8a:	eb95                	bnez	a5,80004abe <pipeclose+0x64>
    release(&pi->lock);
    80004a8c:	8526                	mv	a0,s1
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	210080e7          	jalr	528(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	f66080e7          	jalr	-154(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004aa0:	60e2                	ld	ra,24(sp)
    80004aa2:	6442                	ld	s0,16(sp)
    80004aa4:	64a2                	ld	s1,8(sp)
    80004aa6:	6902                	ld	s2,0(sp)
    80004aa8:	6105                	addi	sp,sp,32
    80004aaa:	8082                	ret
    pi->readopen = 0;
    80004aac:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ab0:	21c48513          	addi	a0,s1,540
    80004ab4:	ffffd097          	auipc	ra,0xffffd
    80004ab8:	69c080e7          	jalr	1692(ra) # 80002150 <wakeup>
    80004abc:	b7e9                	j	80004a86 <pipeclose+0x2c>
    release(&pi->lock);
    80004abe:	8526                	mv	a0,s1
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	1de080e7          	jalr	478(ra) # 80000c9e <release>
}
    80004ac8:	bfe1                	j	80004aa0 <pipeclose+0x46>

0000000080004aca <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aca:	7159                	addi	sp,sp,-112
    80004acc:	f486                	sd	ra,104(sp)
    80004ace:	f0a2                	sd	s0,96(sp)
    80004ad0:	eca6                	sd	s1,88(sp)
    80004ad2:	e8ca                	sd	s2,80(sp)
    80004ad4:	e4ce                	sd	s3,72(sp)
    80004ad6:	e0d2                	sd	s4,64(sp)
    80004ad8:	fc56                	sd	s5,56(sp)
    80004ada:	f85a                	sd	s6,48(sp)
    80004adc:	f45e                	sd	s7,40(sp)
    80004ade:	f062                	sd	s8,32(sp)
    80004ae0:	ec66                	sd	s9,24(sp)
    80004ae2:	1880                	addi	s0,sp,112
    80004ae4:	84aa                	mv	s1,a0
    80004ae6:	8aae                	mv	s5,a1
    80004ae8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004aea:	ffffd097          	auipc	ra,0xffffd
    80004aee:	edc080e7          	jalr	-292(ra) # 800019c6 <myproc>
    80004af2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	0f4080e7          	jalr	244(ra) # 80000bea <acquire>
  while(i < n){
    80004afe:	0d405463          	blez	s4,80004bc6 <pipewrite+0xfc>
    80004b02:	8ba6                	mv	s7,s1
  int i = 0;
    80004b04:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b06:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b08:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b0c:	21c48c13          	addi	s8,s1,540
    80004b10:	a08d                	j	80004b72 <pipewrite+0xa8>
      release(&pi->lock);
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	18a080e7          	jalr	394(ra) # 80000c9e <release>
      return -1;
    80004b1c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b1e:	854a                	mv	a0,s2
    80004b20:	70a6                	ld	ra,104(sp)
    80004b22:	7406                	ld	s0,96(sp)
    80004b24:	64e6                	ld	s1,88(sp)
    80004b26:	6946                	ld	s2,80(sp)
    80004b28:	69a6                	ld	s3,72(sp)
    80004b2a:	6a06                	ld	s4,64(sp)
    80004b2c:	7ae2                	ld	s5,56(sp)
    80004b2e:	7b42                	ld	s6,48(sp)
    80004b30:	7ba2                	ld	s7,40(sp)
    80004b32:	7c02                	ld	s8,32(sp)
    80004b34:	6ce2                	ld	s9,24(sp)
    80004b36:	6165                	addi	sp,sp,112
    80004b38:	8082                	ret
      wakeup(&pi->nread);
    80004b3a:	8566                	mv	a0,s9
    80004b3c:	ffffd097          	auipc	ra,0xffffd
    80004b40:	614080e7          	jalr	1556(ra) # 80002150 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b44:	85de                	mv	a1,s7
    80004b46:	8562                	mv	a0,s8
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	5a4080e7          	jalr	1444(ra) # 800020ec <sleep>
    80004b50:	a839                	j	80004b6e <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b52:	21c4a783          	lw	a5,540(s1)
    80004b56:	0017871b          	addiw	a4,a5,1
    80004b5a:	20e4ae23          	sw	a4,540(s1)
    80004b5e:	1ff7f793          	andi	a5,a5,511
    80004b62:	97a6                	add	a5,a5,s1
    80004b64:	f9f44703          	lbu	a4,-97(s0)
    80004b68:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b6c:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b6e:	05495063          	bge	s2,s4,80004bae <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004b72:	2204a783          	lw	a5,544(s1)
    80004b76:	dfd1                	beqz	a5,80004b12 <pipewrite+0x48>
    80004b78:	854e                	mv	a0,s3
    80004b7a:	ffffe097          	auipc	ra,0xffffe
    80004b7e:	81a080e7          	jalr	-2022(ra) # 80002394 <killed>
    80004b82:	f941                	bnez	a0,80004b12 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b84:	2184a783          	lw	a5,536(s1)
    80004b88:	21c4a703          	lw	a4,540(s1)
    80004b8c:	2007879b          	addiw	a5,a5,512
    80004b90:	faf705e3          	beq	a4,a5,80004b3a <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b94:	4685                	li	a3,1
    80004b96:	01590633          	add	a2,s2,s5
    80004b9a:	f9f40593          	addi	a1,s0,-97
    80004b9e:	0609b503          	ld	a0,96(s3)
    80004ba2:	ffffd097          	auipc	ra,0xffffd
    80004ba6:	b6e080e7          	jalr	-1170(ra) # 80001710 <copyin>
    80004baa:	fb6514e3          	bne	a0,s6,80004b52 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bae:	21848513          	addi	a0,s1,536
    80004bb2:	ffffd097          	auipc	ra,0xffffd
    80004bb6:	59e080e7          	jalr	1438(ra) # 80002150 <wakeup>
  release(&pi->lock);
    80004bba:	8526                	mv	a0,s1
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	0e2080e7          	jalr	226(ra) # 80000c9e <release>
  return i;
    80004bc4:	bfa9                	j	80004b1e <pipewrite+0x54>
  int i = 0;
    80004bc6:	4901                	li	s2,0
    80004bc8:	b7dd                	j	80004bae <pipewrite+0xe4>

0000000080004bca <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bca:	715d                	addi	sp,sp,-80
    80004bcc:	e486                	sd	ra,72(sp)
    80004bce:	e0a2                	sd	s0,64(sp)
    80004bd0:	fc26                	sd	s1,56(sp)
    80004bd2:	f84a                	sd	s2,48(sp)
    80004bd4:	f44e                	sd	s3,40(sp)
    80004bd6:	f052                	sd	s4,32(sp)
    80004bd8:	ec56                	sd	s5,24(sp)
    80004bda:	e85a                	sd	s6,16(sp)
    80004bdc:	0880                	addi	s0,sp,80
    80004bde:	84aa                	mv	s1,a0
    80004be0:	892e                	mv	s2,a1
    80004be2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004be4:	ffffd097          	auipc	ra,0xffffd
    80004be8:	de2080e7          	jalr	-542(ra) # 800019c6 <myproc>
    80004bec:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bee:	8b26                	mv	s6,s1
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	ff8080e7          	jalr	-8(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfa:	2184a703          	lw	a4,536(s1)
    80004bfe:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c02:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c06:	02f71763          	bne	a4,a5,80004c34 <piperead+0x6a>
    80004c0a:	2244a783          	lw	a5,548(s1)
    80004c0e:	c39d                	beqz	a5,80004c34 <piperead+0x6a>
    if(killed(pr)){
    80004c10:	8552                	mv	a0,s4
    80004c12:	ffffd097          	auipc	ra,0xffffd
    80004c16:	782080e7          	jalr	1922(ra) # 80002394 <killed>
    80004c1a:	e941                	bnez	a0,80004caa <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c1c:	85da                	mv	a1,s6
    80004c1e:	854e                	mv	a0,s3
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	4cc080e7          	jalr	1228(ra) # 800020ec <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c28:	2184a703          	lw	a4,536(s1)
    80004c2c:	21c4a783          	lw	a5,540(s1)
    80004c30:	fcf70de3          	beq	a4,a5,80004c0a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c34:	09505263          	blez	s5,80004cb8 <piperead+0xee>
    80004c38:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c3a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c3c:	2184a783          	lw	a5,536(s1)
    80004c40:	21c4a703          	lw	a4,540(s1)
    80004c44:	02f70d63          	beq	a4,a5,80004c7e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c48:	0017871b          	addiw	a4,a5,1
    80004c4c:	20e4ac23          	sw	a4,536(s1)
    80004c50:	1ff7f793          	andi	a5,a5,511
    80004c54:	97a6                	add	a5,a5,s1
    80004c56:	0187c783          	lbu	a5,24(a5)
    80004c5a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c5e:	4685                	li	a3,1
    80004c60:	fbf40613          	addi	a2,s0,-65
    80004c64:	85ca                	mv	a1,s2
    80004c66:	060a3503          	ld	a0,96(s4)
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	a1a080e7          	jalr	-1510(ra) # 80001684 <copyout>
    80004c72:	01650663          	beq	a0,s6,80004c7e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c76:	2985                	addiw	s3,s3,1
    80004c78:	0905                	addi	s2,s2,1
    80004c7a:	fd3a91e3          	bne	s5,s3,80004c3c <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c7e:	21c48513          	addi	a0,s1,540
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	4ce080e7          	jalr	1230(ra) # 80002150 <wakeup>
  release(&pi->lock);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	012080e7          	jalr	18(ra) # 80000c9e <release>
  return i;
}
    80004c94:	854e                	mv	a0,s3
    80004c96:	60a6                	ld	ra,72(sp)
    80004c98:	6406                	ld	s0,64(sp)
    80004c9a:	74e2                	ld	s1,56(sp)
    80004c9c:	7942                	ld	s2,48(sp)
    80004c9e:	79a2                	ld	s3,40(sp)
    80004ca0:	7a02                	ld	s4,32(sp)
    80004ca2:	6ae2                	ld	s5,24(sp)
    80004ca4:	6b42                	ld	s6,16(sp)
    80004ca6:	6161                	addi	sp,sp,80
    80004ca8:	8082                	ret
      release(&pi->lock);
    80004caa:	8526                	mv	a0,s1
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	ff2080e7          	jalr	-14(ra) # 80000c9e <release>
      return -1;
    80004cb4:	59fd                	li	s3,-1
    80004cb6:	bff9                	j	80004c94 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb8:	4981                	li	s3,0
    80004cba:	b7d1                	j	80004c7e <piperead+0xb4>

0000000080004cbc <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cbc:	1141                	addi	sp,sp,-16
    80004cbe:	e422                	sd	s0,8(sp)
    80004cc0:	0800                	addi	s0,sp,16
    80004cc2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cc4:	8905                	andi	a0,a0,1
    80004cc6:	c111                	beqz	a0,80004cca <flags2perm+0xe>
      perm = PTE_X;
    80004cc8:	4521                	li	a0,8
    if(flags & 0x2)
    80004cca:	8b89                	andi	a5,a5,2
    80004ccc:	c399                	beqz	a5,80004cd2 <flags2perm+0x16>
      perm |= PTE_W;
    80004cce:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cd2:	6422                	ld	s0,8(sp)
    80004cd4:	0141                	addi	sp,sp,16
    80004cd6:	8082                	ret

0000000080004cd8 <exec>:

int
exec(char *path, char **argv)
{
    80004cd8:	df010113          	addi	sp,sp,-528
    80004cdc:	20113423          	sd	ra,520(sp)
    80004ce0:	20813023          	sd	s0,512(sp)
    80004ce4:	ffa6                	sd	s1,504(sp)
    80004ce6:	fbca                	sd	s2,496(sp)
    80004ce8:	f7ce                	sd	s3,488(sp)
    80004cea:	f3d2                	sd	s4,480(sp)
    80004cec:	efd6                	sd	s5,472(sp)
    80004cee:	ebda                	sd	s6,464(sp)
    80004cf0:	e7de                	sd	s7,456(sp)
    80004cf2:	e3e2                	sd	s8,448(sp)
    80004cf4:	ff66                	sd	s9,440(sp)
    80004cf6:	fb6a                	sd	s10,432(sp)
    80004cf8:	f76e                	sd	s11,424(sp)
    80004cfa:	0c00                	addi	s0,sp,528
    80004cfc:	84aa                	mv	s1,a0
    80004cfe:	dea43c23          	sd	a0,-520(s0)
    80004d02:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d06:	ffffd097          	auipc	ra,0xffffd
    80004d0a:	cc0080e7          	jalr	-832(ra) # 800019c6 <myproc>
    80004d0e:	892a                	mv	s2,a0

  begin_op();
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	474080e7          	jalr	1140(ra) # 80004184 <begin_op>

  if((ip = namei(path)) == 0){
    80004d18:	8526                	mv	a0,s1
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	24e080e7          	jalr	590(ra) # 80003f68 <namei>
    80004d22:	c92d                	beqz	a0,80004d94 <exec+0xbc>
    80004d24:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	a9c080e7          	jalr	-1380(ra) # 800037c2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d2e:	04000713          	li	a4,64
    80004d32:	4681                	li	a3,0
    80004d34:	e5040613          	addi	a2,s0,-432
    80004d38:	4581                	li	a1,0
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	d3a080e7          	jalr	-710(ra) # 80003a76 <readi>
    80004d44:	04000793          	li	a5,64
    80004d48:	00f51a63          	bne	a0,a5,80004d5c <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d4c:	e5042703          	lw	a4,-432(s0)
    80004d50:	464c47b7          	lui	a5,0x464c4
    80004d54:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d58:	04f70463          	beq	a4,a5,80004da0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d5c:	8526                	mv	a0,s1
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	cc6080e7          	jalr	-826(ra) # 80003a24 <iunlockput>
    end_op();
    80004d66:	fffff097          	auipc	ra,0xfffff
    80004d6a:	49e080e7          	jalr	1182(ra) # 80004204 <end_op>
  }
  return -1;
    80004d6e:	557d                	li	a0,-1
}
    80004d70:	20813083          	ld	ra,520(sp)
    80004d74:	20013403          	ld	s0,512(sp)
    80004d78:	74fe                	ld	s1,504(sp)
    80004d7a:	795e                	ld	s2,496(sp)
    80004d7c:	79be                	ld	s3,488(sp)
    80004d7e:	7a1e                	ld	s4,480(sp)
    80004d80:	6afe                	ld	s5,472(sp)
    80004d82:	6b5e                	ld	s6,464(sp)
    80004d84:	6bbe                	ld	s7,456(sp)
    80004d86:	6c1e                	ld	s8,448(sp)
    80004d88:	7cfa                	ld	s9,440(sp)
    80004d8a:	7d5a                	ld	s10,432(sp)
    80004d8c:	7dba                	ld	s11,424(sp)
    80004d8e:	21010113          	addi	sp,sp,528
    80004d92:	8082                	ret
    end_op();
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	470080e7          	jalr	1136(ra) # 80004204 <end_op>
    return -1;
    80004d9c:	557d                	li	a0,-1
    80004d9e:	bfc9                	j	80004d70 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004da0:	854a                	mv	a0,s2
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	ce8080e7          	jalr	-792(ra) # 80001a8a <proc_pagetable>
    80004daa:	8baa                	mv	s7,a0
    80004dac:	d945                	beqz	a0,80004d5c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dae:	e7042983          	lw	s3,-400(s0)
    80004db2:	e8845783          	lhu	a5,-376(s0)
    80004db6:	c7ad                	beqz	a5,80004e20 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004db8:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dba:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004dbc:	6c85                	lui	s9,0x1
    80004dbe:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dc2:	def43823          	sd	a5,-528(s0)
    80004dc6:	ac0d                	j	80004ff8 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dc8:	00004517          	auipc	a0,0x4
    80004dcc:	93850513          	addi	a0,a0,-1736 # 80008700 <syscalls+0x290>
    80004dd0:	ffffb097          	auipc	ra,0xffffb
    80004dd4:	774080e7          	jalr	1908(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dd8:	8756                	mv	a4,s5
    80004dda:	012d86bb          	addw	a3,s11,s2
    80004dde:	4581                	li	a1,0
    80004de0:	8526                	mv	a0,s1
    80004de2:	fffff097          	auipc	ra,0xfffff
    80004de6:	c94080e7          	jalr	-876(ra) # 80003a76 <readi>
    80004dea:	2501                	sext.w	a0,a0
    80004dec:	1aaa9a63          	bne	s5,a0,80004fa0 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004df0:	6785                	lui	a5,0x1
    80004df2:	0127893b          	addw	s2,a5,s2
    80004df6:	77fd                	lui	a5,0xfffff
    80004df8:	01478a3b          	addw	s4,a5,s4
    80004dfc:	1f897563          	bgeu	s2,s8,80004fe6 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004e00:	02091593          	slli	a1,s2,0x20
    80004e04:	9181                	srli	a1,a1,0x20
    80004e06:	95ea                	add	a1,a1,s10
    80004e08:	855e                	mv	a0,s7
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	26e080e7          	jalr	622(ra) # 80001078 <walkaddr>
    80004e12:	862a                	mv	a2,a0
    if(pa == 0)
    80004e14:	d955                	beqz	a0,80004dc8 <exec+0xf0>
      n = PGSIZE;
    80004e16:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e18:	fd9a70e3          	bgeu	s4,s9,80004dd8 <exec+0x100>
      n = sz - i;
    80004e1c:	8ad2                	mv	s5,s4
    80004e1e:	bf6d                	j	80004dd8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e20:	4a01                	li	s4,0
  iunlockput(ip);
    80004e22:	8526                	mv	a0,s1
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	c00080e7          	jalr	-1024(ra) # 80003a24 <iunlockput>
  end_op();
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	3d8080e7          	jalr	984(ra) # 80004204 <end_op>
  p = myproc();
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	b92080e7          	jalr	-1134(ra) # 800019c6 <myproc>
    80004e3c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e3e:	05853d03          	ld	s10,88(a0)
  sz = PGROUNDUP(sz);
    80004e42:	6785                	lui	a5,0x1
    80004e44:	17fd                	addi	a5,a5,-1
    80004e46:	9a3e                	add	s4,s4,a5
    80004e48:	757d                	lui	a0,0xfffff
    80004e4a:	00aa77b3          	and	a5,s4,a0
    80004e4e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e52:	4691                	li	a3,4
    80004e54:	6609                	lui	a2,0x2
    80004e56:	963e                	add	a2,a2,a5
    80004e58:	85be                	mv	a1,a5
    80004e5a:	855e                	mv	a0,s7
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	5d0080e7          	jalr	1488(ra) # 8000142c <uvmalloc>
    80004e64:	8b2a                	mv	s6,a0
  ip = 0;
    80004e66:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e68:	12050c63          	beqz	a0,80004fa0 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e6c:	75f9                	lui	a1,0xffffe
    80004e6e:	95aa                	add	a1,a1,a0
    80004e70:	855e                	mv	a0,s7
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	7e0080e7          	jalr	2016(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e7a:	7c7d                	lui	s8,0xfffff
    80004e7c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e7e:	e0043783          	ld	a5,-512(s0)
    80004e82:	6388                	ld	a0,0(a5)
    80004e84:	c535                	beqz	a0,80004ef0 <exec+0x218>
    80004e86:	e9040993          	addi	s3,s0,-368
    80004e8a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e8e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	fda080e7          	jalr	-38(ra) # 80000e6a <strlen>
    80004e98:	2505                	addiw	a0,a0,1
    80004e9a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e9e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ea2:	13896663          	bltu	s2,s8,80004fce <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ea6:	e0043d83          	ld	s11,-512(s0)
    80004eaa:	000dba03          	ld	s4,0(s11)
    80004eae:	8552                	mv	a0,s4
    80004eb0:	ffffc097          	auipc	ra,0xffffc
    80004eb4:	fba080e7          	jalr	-70(ra) # 80000e6a <strlen>
    80004eb8:	0015069b          	addiw	a3,a0,1
    80004ebc:	8652                	mv	a2,s4
    80004ebe:	85ca                	mv	a1,s2
    80004ec0:	855e                	mv	a0,s7
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	7c2080e7          	jalr	1986(ra) # 80001684 <copyout>
    80004eca:	10054663          	bltz	a0,80004fd6 <exec+0x2fe>
    ustack[argc] = sp;
    80004ece:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ed2:	0485                	addi	s1,s1,1
    80004ed4:	008d8793          	addi	a5,s11,8
    80004ed8:	e0f43023          	sd	a5,-512(s0)
    80004edc:	008db503          	ld	a0,8(s11)
    80004ee0:	c911                	beqz	a0,80004ef4 <exec+0x21c>
    if(argc >= MAXARG)
    80004ee2:	09a1                	addi	s3,s3,8
    80004ee4:	fb3c96e3          	bne	s9,s3,80004e90 <exec+0x1b8>
  sz = sz1;
    80004ee8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eec:	4481                	li	s1,0
    80004eee:	a84d                	j	80004fa0 <exec+0x2c8>
  sp = sz;
    80004ef0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ef2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ef4:	00349793          	slli	a5,s1,0x3
    80004ef8:	f9040713          	addi	a4,s0,-112
    80004efc:	97ba                	add	a5,a5,a4
    80004efe:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f02:	00148693          	addi	a3,s1,1
    80004f06:	068e                	slli	a3,a3,0x3
    80004f08:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f0c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f10:	01897663          	bgeu	s2,s8,80004f1c <exec+0x244>
  sz = sz1;
    80004f14:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f18:	4481                	li	s1,0
    80004f1a:	a059                	j	80004fa0 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f1c:	e9040613          	addi	a2,s0,-368
    80004f20:	85ca                	mv	a1,s2
    80004f22:	855e                	mv	a0,s7
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	760080e7          	jalr	1888(ra) # 80001684 <copyout>
    80004f2c:	0a054963          	bltz	a0,80004fde <exec+0x306>
  p->trapframe->a1 = sp;
    80004f30:	068ab783          	ld	a5,104(s5)
    80004f34:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f38:	df843783          	ld	a5,-520(s0)
    80004f3c:	0007c703          	lbu	a4,0(a5)
    80004f40:	cf11                	beqz	a4,80004f5c <exec+0x284>
    80004f42:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f44:	02f00693          	li	a3,47
    80004f48:	a039                	j	80004f56 <exec+0x27e>
      last = s+1;
    80004f4a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f4e:	0785                	addi	a5,a5,1
    80004f50:	fff7c703          	lbu	a4,-1(a5)
    80004f54:	c701                	beqz	a4,80004f5c <exec+0x284>
    if(*s == '/')
    80004f56:	fed71ce3          	bne	a4,a3,80004f4e <exec+0x276>
    80004f5a:	bfc5                	j	80004f4a <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f5c:	4641                	li	a2,16
    80004f5e:	df843583          	ld	a1,-520(s0)
    80004f62:	168a8513          	addi	a0,s5,360
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	ed2080e7          	jalr	-302(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f6e:	060ab503          	ld	a0,96(s5)
  p->pagetable = pagetable;
    80004f72:	077ab023          	sd	s7,96(s5)
  p->sz = sz;
    80004f76:	056abc23          	sd	s6,88(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f7a:	068ab783          	ld	a5,104(s5)
    80004f7e:	e6843703          	ld	a4,-408(s0)
    80004f82:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f84:	068ab783          	ld	a5,104(s5)
    80004f88:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f8c:	85ea                	mv	a1,s10
    80004f8e:	ffffd097          	auipc	ra,0xffffd
    80004f92:	b98080e7          	jalr	-1128(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f96:	0004851b          	sext.w	a0,s1
    80004f9a:	bbd9                	j	80004d70 <exec+0x98>
    80004f9c:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fa0:	e0843583          	ld	a1,-504(s0)
    80004fa4:	855e                	mv	a0,s7
    80004fa6:	ffffd097          	auipc	ra,0xffffd
    80004faa:	b80080e7          	jalr	-1152(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004fae:	da0497e3          	bnez	s1,80004d5c <exec+0x84>
  return -1;
    80004fb2:	557d                	li	a0,-1
    80004fb4:	bb75                	j	80004d70 <exec+0x98>
    80004fb6:	e1443423          	sd	s4,-504(s0)
    80004fba:	b7dd                	j	80004fa0 <exec+0x2c8>
    80004fbc:	e1443423          	sd	s4,-504(s0)
    80004fc0:	b7c5                	j	80004fa0 <exec+0x2c8>
    80004fc2:	e1443423          	sd	s4,-504(s0)
    80004fc6:	bfe9                	j	80004fa0 <exec+0x2c8>
    80004fc8:	e1443423          	sd	s4,-504(s0)
    80004fcc:	bfd1                	j	80004fa0 <exec+0x2c8>
  sz = sz1;
    80004fce:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fd2:	4481                	li	s1,0
    80004fd4:	b7f1                	j	80004fa0 <exec+0x2c8>
  sz = sz1;
    80004fd6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fda:	4481                	li	s1,0
    80004fdc:	b7d1                	j	80004fa0 <exec+0x2c8>
  sz = sz1;
    80004fde:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe2:	4481                	li	s1,0
    80004fe4:	bf75                	j	80004fa0 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fe6:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fea:	2b05                	addiw	s6,s6,1
    80004fec:	0389899b          	addiw	s3,s3,56
    80004ff0:	e8845783          	lhu	a5,-376(s0)
    80004ff4:	e2fb57e3          	bge	s6,a5,80004e22 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ff8:	2981                	sext.w	s3,s3
    80004ffa:	03800713          	li	a4,56
    80004ffe:	86ce                	mv	a3,s3
    80005000:	e1840613          	addi	a2,s0,-488
    80005004:	4581                	li	a1,0
    80005006:	8526                	mv	a0,s1
    80005008:	fffff097          	auipc	ra,0xfffff
    8000500c:	a6e080e7          	jalr	-1426(ra) # 80003a76 <readi>
    80005010:	03800793          	li	a5,56
    80005014:	f8f514e3          	bne	a0,a5,80004f9c <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005018:	e1842783          	lw	a5,-488(s0)
    8000501c:	4705                	li	a4,1
    8000501e:	fce796e3          	bne	a5,a4,80004fea <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005022:	e4043903          	ld	s2,-448(s0)
    80005026:	e3843783          	ld	a5,-456(s0)
    8000502a:	f8f966e3          	bltu	s2,a5,80004fb6 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000502e:	e2843783          	ld	a5,-472(s0)
    80005032:	993e                	add	s2,s2,a5
    80005034:	f8f964e3          	bltu	s2,a5,80004fbc <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005038:	df043703          	ld	a4,-528(s0)
    8000503c:	8ff9                	and	a5,a5,a4
    8000503e:	f3d1                	bnez	a5,80004fc2 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005040:	e1c42503          	lw	a0,-484(s0)
    80005044:	00000097          	auipc	ra,0x0
    80005048:	c78080e7          	jalr	-904(ra) # 80004cbc <flags2perm>
    8000504c:	86aa                	mv	a3,a0
    8000504e:	864a                	mv	a2,s2
    80005050:	85d2                	mv	a1,s4
    80005052:	855e                	mv	a0,s7
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	3d8080e7          	jalr	984(ra) # 8000142c <uvmalloc>
    8000505c:	e0a43423          	sd	a0,-504(s0)
    80005060:	d525                	beqz	a0,80004fc8 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005062:	e2843d03          	ld	s10,-472(s0)
    80005066:	e2042d83          	lw	s11,-480(s0)
    8000506a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000506e:	f60c0ce3          	beqz	s8,80004fe6 <exec+0x30e>
    80005072:	8a62                	mv	s4,s8
    80005074:	4901                	li	s2,0
    80005076:	b369                	j	80004e00 <exec+0x128>

0000000080005078 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005078:	7179                	addi	sp,sp,-48
    8000507a:	f406                	sd	ra,40(sp)
    8000507c:	f022                	sd	s0,32(sp)
    8000507e:	ec26                	sd	s1,24(sp)
    80005080:	e84a                	sd	s2,16(sp)
    80005082:	1800                	addi	s0,sp,48
    80005084:	892e                	mv	s2,a1
    80005086:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005088:	fdc40593          	addi	a1,s0,-36
    8000508c:	ffffe097          	auipc	ra,0xffffe
    80005090:	b88080e7          	jalr	-1144(ra) # 80002c14 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005094:	fdc42703          	lw	a4,-36(s0)
    80005098:	47bd                	li	a5,15
    8000509a:	02e7eb63          	bltu	a5,a4,800050d0 <argfd+0x58>
    8000509e:	ffffd097          	auipc	ra,0xffffd
    800050a2:	928080e7          	jalr	-1752(ra) # 800019c6 <myproc>
    800050a6:	fdc42703          	lw	a4,-36(s0)
    800050aa:	01c70793          	addi	a5,a4,28
    800050ae:	078e                	slli	a5,a5,0x3
    800050b0:	953e                	add	a0,a0,a5
    800050b2:	611c                	ld	a5,0(a0)
    800050b4:	c385                	beqz	a5,800050d4 <argfd+0x5c>
    return -1;
  if(pfd)
    800050b6:	00090463          	beqz	s2,800050be <argfd+0x46>
    *pfd = fd;
    800050ba:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050be:	4501                	li	a0,0
  if(pf)
    800050c0:	c091                	beqz	s1,800050c4 <argfd+0x4c>
    *pf = f;
    800050c2:	e09c                	sd	a5,0(s1)
}
    800050c4:	70a2                	ld	ra,40(sp)
    800050c6:	7402                	ld	s0,32(sp)
    800050c8:	64e2                	ld	s1,24(sp)
    800050ca:	6942                	ld	s2,16(sp)
    800050cc:	6145                	addi	sp,sp,48
    800050ce:	8082                	ret
    return -1;
    800050d0:	557d                	li	a0,-1
    800050d2:	bfcd                	j	800050c4 <argfd+0x4c>
    800050d4:	557d                	li	a0,-1
    800050d6:	b7fd                	j	800050c4 <argfd+0x4c>

00000000800050d8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050d8:	1101                	addi	sp,sp,-32
    800050da:	ec06                	sd	ra,24(sp)
    800050dc:	e822                	sd	s0,16(sp)
    800050de:	e426                	sd	s1,8(sp)
    800050e0:	1000                	addi	s0,sp,32
    800050e2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050e4:	ffffd097          	auipc	ra,0xffffd
    800050e8:	8e2080e7          	jalr	-1822(ra) # 800019c6 <myproc>
    800050ec:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050ee:	0e050793          	addi	a5,a0,224 # fffffffffffff0e0 <end+0xffffffff7ffdcf50>
    800050f2:	4501                	li	a0,0
    800050f4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050f6:	6398                	ld	a4,0(a5)
    800050f8:	cb19                	beqz	a4,8000510e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050fa:	2505                	addiw	a0,a0,1
    800050fc:	07a1                	addi	a5,a5,8
    800050fe:	fed51ce3          	bne	a0,a3,800050f6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005102:	557d                	li	a0,-1
}
    80005104:	60e2                	ld	ra,24(sp)
    80005106:	6442                	ld	s0,16(sp)
    80005108:	64a2                	ld	s1,8(sp)
    8000510a:	6105                	addi	sp,sp,32
    8000510c:	8082                	ret
      p->ofile[fd] = f;
    8000510e:	01c50793          	addi	a5,a0,28
    80005112:	078e                	slli	a5,a5,0x3
    80005114:	963e                	add	a2,a2,a5
    80005116:	e204                	sd	s1,0(a2)
      return fd;
    80005118:	b7f5                	j	80005104 <fdalloc+0x2c>

000000008000511a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000511a:	715d                	addi	sp,sp,-80
    8000511c:	e486                	sd	ra,72(sp)
    8000511e:	e0a2                	sd	s0,64(sp)
    80005120:	fc26                	sd	s1,56(sp)
    80005122:	f84a                	sd	s2,48(sp)
    80005124:	f44e                	sd	s3,40(sp)
    80005126:	f052                	sd	s4,32(sp)
    80005128:	ec56                	sd	s5,24(sp)
    8000512a:	e85a                	sd	s6,16(sp)
    8000512c:	0880                	addi	s0,sp,80
    8000512e:	8b2e                	mv	s6,a1
    80005130:	89b2                	mv	s3,a2
    80005132:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005134:	fb040593          	addi	a1,s0,-80
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	e4e080e7          	jalr	-434(ra) # 80003f86 <nameiparent>
    80005140:	84aa                	mv	s1,a0
    80005142:	16050063          	beqz	a0,800052a2 <create+0x188>
    return 0;

  ilock(dp);
    80005146:	ffffe097          	auipc	ra,0xffffe
    8000514a:	67c080e7          	jalr	1660(ra) # 800037c2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000514e:	4601                	li	a2,0
    80005150:	fb040593          	addi	a1,s0,-80
    80005154:	8526                	mv	a0,s1
    80005156:	fffff097          	auipc	ra,0xfffff
    8000515a:	b50080e7          	jalr	-1200(ra) # 80003ca6 <dirlookup>
    8000515e:	8aaa                	mv	s5,a0
    80005160:	c931                	beqz	a0,800051b4 <create+0x9a>
    iunlockput(dp);
    80005162:	8526                	mv	a0,s1
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	8c0080e7          	jalr	-1856(ra) # 80003a24 <iunlockput>
    ilock(ip);
    8000516c:	8556                	mv	a0,s5
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	654080e7          	jalr	1620(ra) # 800037c2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005176:	000b059b          	sext.w	a1,s6
    8000517a:	4789                	li	a5,2
    8000517c:	02f59563          	bne	a1,a5,800051a6 <create+0x8c>
    80005180:	044ad783          	lhu	a5,68(s5)
    80005184:	37f9                	addiw	a5,a5,-2
    80005186:	17c2                	slli	a5,a5,0x30
    80005188:	93c1                	srli	a5,a5,0x30
    8000518a:	4705                	li	a4,1
    8000518c:	00f76d63          	bltu	a4,a5,800051a6 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005190:	8556                	mv	a0,s5
    80005192:	60a6                	ld	ra,72(sp)
    80005194:	6406                	ld	s0,64(sp)
    80005196:	74e2                	ld	s1,56(sp)
    80005198:	7942                	ld	s2,48(sp)
    8000519a:	79a2                	ld	s3,40(sp)
    8000519c:	7a02                	ld	s4,32(sp)
    8000519e:	6ae2                	ld	s5,24(sp)
    800051a0:	6b42                	ld	s6,16(sp)
    800051a2:	6161                	addi	sp,sp,80
    800051a4:	8082                	ret
    iunlockput(ip);
    800051a6:	8556                	mv	a0,s5
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	87c080e7          	jalr	-1924(ra) # 80003a24 <iunlockput>
    return 0;
    800051b0:	4a81                	li	s5,0
    800051b2:	bff9                	j	80005190 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051b4:	85da                	mv	a1,s6
    800051b6:	4088                	lw	a0,0(s1)
    800051b8:	ffffe097          	auipc	ra,0xffffe
    800051bc:	46e080e7          	jalr	1134(ra) # 80003626 <ialloc>
    800051c0:	8a2a                	mv	s4,a0
    800051c2:	c921                	beqz	a0,80005212 <create+0xf8>
  ilock(ip);
    800051c4:	ffffe097          	auipc	ra,0xffffe
    800051c8:	5fe080e7          	jalr	1534(ra) # 800037c2 <ilock>
  ip->major = major;
    800051cc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051d0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051d4:	4785                	li	a5,1
    800051d6:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800051da:	8552                	mv	a0,s4
    800051dc:	ffffe097          	auipc	ra,0xffffe
    800051e0:	51c080e7          	jalr	1308(ra) # 800036f8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051e4:	000b059b          	sext.w	a1,s6
    800051e8:	4785                	li	a5,1
    800051ea:	02f58b63          	beq	a1,a5,80005220 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800051ee:	004a2603          	lw	a2,4(s4)
    800051f2:	fb040593          	addi	a1,s0,-80
    800051f6:	8526                	mv	a0,s1
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	cbe080e7          	jalr	-834(ra) # 80003eb6 <dirlink>
    80005200:	06054f63          	bltz	a0,8000527e <create+0x164>
  iunlockput(dp);
    80005204:	8526                	mv	a0,s1
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	81e080e7          	jalr	-2018(ra) # 80003a24 <iunlockput>
  return ip;
    8000520e:	8ad2                	mv	s5,s4
    80005210:	b741                	j	80005190 <create+0x76>
    iunlockput(dp);
    80005212:	8526                	mv	a0,s1
    80005214:	fffff097          	auipc	ra,0xfffff
    80005218:	810080e7          	jalr	-2032(ra) # 80003a24 <iunlockput>
    return 0;
    8000521c:	8ad2                	mv	s5,s4
    8000521e:	bf8d                	j	80005190 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005220:	004a2603          	lw	a2,4(s4)
    80005224:	00003597          	auipc	a1,0x3
    80005228:	4fc58593          	addi	a1,a1,1276 # 80008720 <syscalls+0x2b0>
    8000522c:	8552                	mv	a0,s4
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	c88080e7          	jalr	-888(ra) # 80003eb6 <dirlink>
    80005236:	04054463          	bltz	a0,8000527e <create+0x164>
    8000523a:	40d0                	lw	a2,4(s1)
    8000523c:	00003597          	auipc	a1,0x3
    80005240:	4ec58593          	addi	a1,a1,1260 # 80008728 <syscalls+0x2b8>
    80005244:	8552                	mv	a0,s4
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	c70080e7          	jalr	-912(ra) # 80003eb6 <dirlink>
    8000524e:	02054863          	bltz	a0,8000527e <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005252:	004a2603          	lw	a2,4(s4)
    80005256:	fb040593          	addi	a1,s0,-80
    8000525a:	8526                	mv	a0,s1
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	c5a080e7          	jalr	-934(ra) # 80003eb6 <dirlink>
    80005264:	00054d63          	bltz	a0,8000527e <create+0x164>
    dp->nlink++;  // for ".."
    80005268:	04a4d783          	lhu	a5,74(s1)
    8000526c:	2785                	addiw	a5,a5,1
    8000526e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005272:	8526                	mv	a0,s1
    80005274:	ffffe097          	auipc	ra,0xffffe
    80005278:	484080e7          	jalr	1156(ra) # 800036f8 <iupdate>
    8000527c:	b761                	j	80005204 <create+0xea>
  ip->nlink = 0;
    8000527e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005282:	8552                	mv	a0,s4
    80005284:	ffffe097          	auipc	ra,0xffffe
    80005288:	474080e7          	jalr	1140(ra) # 800036f8 <iupdate>
  iunlockput(ip);
    8000528c:	8552                	mv	a0,s4
    8000528e:	ffffe097          	auipc	ra,0xffffe
    80005292:	796080e7          	jalr	1942(ra) # 80003a24 <iunlockput>
  iunlockput(dp);
    80005296:	8526                	mv	a0,s1
    80005298:	ffffe097          	auipc	ra,0xffffe
    8000529c:	78c080e7          	jalr	1932(ra) # 80003a24 <iunlockput>
  return 0;
    800052a0:	bdc5                	j	80005190 <create+0x76>
    return 0;
    800052a2:	8aaa                	mv	s5,a0
    800052a4:	b5f5                	j	80005190 <create+0x76>

00000000800052a6 <sys_dup>:
{
    800052a6:	7179                	addi	sp,sp,-48
    800052a8:	f406                	sd	ra,40(sp)
    800052aa:	f022                	sd	s0,32(sp)
    800052ac:	ec26                	sd	s1,24(sp)
    800052ae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052b0:	fd840613          	addi	a2,s0,-40
    800052b4:	4581                	li	a1,0
    800052b6:	4501                	li	a0,0
    800052b8:	00000097          	auipc	ra,0x0
    800052bc:	dc0080e7          	jalr	-576(ra) # 80005078 <argfd>
    return -1;
    800052c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052c2:	02054363          	bltz	a0,800052e8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052c6:	fd843503          	ld	a0,-40(s0)
    800052ca:	00000097          	auipc	ra,0x0
    800052ce:	e0e080e7          	jalr	-498(ra) # 800050d8 <fdalloc>
    800052d2:	84aa                	mv	s1,a0
    return -1;
    800052d4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052d6:	00054963          	bltz	a0,800052e8 <sys_dup+0x42>
  filedup(f);
    800052da:	fd843503          	ld	a0,-40(s0)
    800052de:	fffff097          	auipc	ra,0xfffff
    800052e2:	320080e7          	jalr	800(ra) # 800045fe <filedup>
  return fd;
    800052e6:	87a6                	mv	a5,s1
}
    800052e8:	853e                	mv	a0,a5
    800052ea:	70a2                	ld	ra,40(sp)
    800052ec:	7402                	ld	s0,32(sp)
    800052ee:	64e2                	ld	s1,24(sp)
    800052f0:	6145                	addi	sp,sp,48
    800052f2:	8082                	ret

00000000800052f4 <sys_read>:
{
    800052f4:	7179                	addi	sp,sp,-48
    800052f6:	f406                	sd	ra,40(sp)
    800052f8:	f022                	sd	s0,32(sp)
    800052fa:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052fc:	fd840593          	addi	a1,s0,-40
    80005300:	4505                	li	a0,1
    80005302:	ffffe097          	auipc	ra,0xffffe
    80005306:	932080e7          	jalr	-1742(ra) # 80002c34 <argaddr>
  argint(2, &n);
    8000530a:	fe440593          	addi	a1,s0,-28
    8000530e:	4509                	li	a0,2
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	904080e7          	jalr	-1788(ra) # 80002c14 <argint>
  if(argfd(0, 0, &f) < 0)
    80005318:	fe840613          	addi	a2,s0,-24
    8000531c:	4581                	li	a1,0
    8000531e:	4501                	li	a0,0
    80005320:	00000097          	auipc	ra,0x0
    80005324:	d58080e7          	jalr	-680(ra) # 80005078 <argfd>
    80005328:	87aa                	mv	a5,a0
    return -1;
    8000532a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000532c:	0007cc63          	bltz	a5,80005344 <sys_read+0x50>
  return fileread(f, p, n);
    80005330:	fe442603          	lw	a2,-28(s0)
    80005334:	fd843583          	ld	a1,-40(s0)
    80005338:	fe843503          	ld	a0,-24(s0)
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	44e080e7          	jalr	1102(ra) # 8000478a <fileread>
}
    80005344:	70a2                	ld	ra,40(sp)
    80005346:	7402                	ld	s0,32(sp)
    80005348:	6145                	addi	sp,sp,48
    8000534a:	8082                	ret

000000008000534c <sys_write>:
{
    8000534c:	7179                	addi	sp,sp,-48
    8000534e:	f406                	sd	ra,40(sp)
    80005350:	f022                	sd	s0,32(sp)
    80005352:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005354:	fd840593          	addi	a1,s0,-40
    80005358:	4505                	li	a0,1
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	8da080e7          	jalr	-1830(ra) # 80002c34 <argaddr>
  argint(2, &n);
    80005362:	fe440593          	addi	a1,s0,-28
    80005366:	4509                	li	a0,2
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	8ac080e7          	jalr	-1876(ra) # 80002c14 <argint>
  if(argfd(0, 0, &f) < 0)
    80005370:	fe840613          	addi	a2,s0,-24
    80005374:	4581                	li	a1,0
    80005376:	4501                	li	a0,0
    80005378:	00000097          	auipc	ra,0x0
    8000537c:	d00080e7          	jalr	-768(ra) # 80005078 <argfd>
    80005380:	87aa                	mv	a5,a0
    return -1;
    80005382:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005384:	0007cc63          	bltz	a5,8000539c <sys_write+0x50>
  return filewrite(f, p, n);
    80005388:	fe442603          	lw	a2,-28(s0)
    8000538c:	fd843583          	ld	a1,-40(s0)
    80005390:	fe843503          	ld	a0,-24(s0)
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	4b8080e7          	jalr	1208(ra) # 8000484c <filewrite>
}
    8000539c:	70a2                	ld	ra,40(sp)
    8000539e:	7402                	ld	s0,32(sp)
    800053a0:	6145                	addi	sp,sp,48
    800053a2:	8082                	ret

00000000800053a4 <sys_close>:
{
    800053a4:	1101                	addi	sp,sp,-32
    800053a6:	ec06                	sd	ra,24(sp)
    800053a8:	e822                	sd	s0,16(sp)
    800053aa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053ac:	fe040613          	addi	a2,s0,-32
    800053b0:	fec40593          	addi	a1,s0,-20
    800053b4:	4501                	li	a0,0
    800053b6:	00000097          	auipc	ra,0x0
    800053ba:	cc2080e7          	jalr	-830(ra) # 80005078 <argfd>
    return -1;
    800053be:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053c0:	02054463          	bltz	a0,800053e8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	602080e7          	jalr	1538(ra) # 800019c6 <myproc>
    800053cc:	fec42783          	lw	a5,-20(s0)
    800053d0:	07f1                	addi	a5,a5,28
    800053d2:	078e                	slli	a5,a5,0x3
    800053d4:	97aa                	add	a5,a5,a0
    800053d6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053da:	fe043503          	ld	a0,-32(s0)
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	272080e7          	jalr	626(ra) # 80004650 <fileclose>
  return 0;
    800053e6:	4781                	li	a5,0
}
    800053e8:	853e                	mv	a0,a5
    800053ea:	60e2                	ld	ra,24(sp)
    800053ec:	6442                	ld	s0,16(sp)
    800053ee:	6105                	addi	sp,sp,32
    800053f0:	8082                	ret

00000000800053f2 <sys_fstat>:
{
    800053f2:	1101                	addi	sp,sp,-32
    800053f4:	ec06                	sd	ra,24(sp)
    800053f6:	e822                	sd	s0,16(sp)
    800053f8:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053fa:	fe040593          	addi	a1,s0,-32
    800053fe:	4505                	li	a0,1
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	834080e7          	jalr	-1996(ra) # 80002c34 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005408:	fe840613          	addi	a2,s0,-24
    8000540c:	4581                	li	a1,0
    8000540e:	4501                	li	a0,0
    80005410:	00000097          	auipc	ra,0x0
    80005414:	c68080e7          	jalr	-920(ra) # 80005078 <argfd>
    80005418:	87aa                	mv	a5,a0
    return -1;
    8000541a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000541c:	0007ca63          	bltz	a5,80005430 <sys_fstat+0x3e>
  return filestat(f, st);
    80005420:	fe043583          	ld	a1,-32(s0)
    80005424:	fe843503          	ld	a0,-24(s0)
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	2f0080e7          	jalr	752(ra) # 80004718 <filestat>
}
    80005430:	60e2                	ld	ra,24(sp)
    80005432:	6442                	ld	s0,16(sp)
    80005434:	6105                	addi	sp,sp,32
    80005436:	8082                	ret

0000000080005438 <sys_link>:
{
    80005438:	7169                	addi	sp,sp,-304
    8000543a:	f606                	sd	ra,296(sp)
    8000543c:	f222                	sd	s0,288(sp)
    8000543e:	ee26                	sd	s1,280(sp)
    80005440:	ea4a                	sd	s2,272(sp)
    80005442:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005444:	08000613          	li	a2,128
    80005448:	ed040593          	addi	a1,s0,-304
    8000544c:	4501                	li	a0,0
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	806080e7          	jalr	-2042(ra) # 80002c54 <argstr>
    return -1;
    80005456:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005458:	10054e63          	bltz	a0,80005574 <sys_link+0x13c>
    8000545c:	08000613          	li	a2,128
    80005460:	f5040593          	addi	a1,s0,-176
    80005464:	4505                	li	a0,1
    80005466:	ffffd097          	auipc	ra,0xffffd
    8000546a:	7ee080e7          	jalr	2030(ra) # 80002c54 <argstr>
    return -1;
    8000546e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005470:	10054263          	bltz	a0,80005574 <sys_link+0x13c>
  begin_op();
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	d10080e7          	jalr	-752(ra) # 80004184 <begin_op>
  if((ip = namei(old)) == 0){
    8000547c:	ed040513          	addi	a0,s0,-304
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	ae8080e7          	jalr	-1304(ra) # 80003f68 <namei>
    80005488:	84aa                	mv	s1,a0
    8000548a:	c551                	beqz	a0,80005516 <sys_link+0xde>
  ilock(ip);
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	336080e7          	jalr	822(ra) # 800037c2 <ilock>
  if(ip->type == T_DIR){
    80005494:	04449703          	lh	a4,68(s1)
    80005498:	4785                	li	a5,1
    8000549a:	08f70463          	beq	a4,a5,80005522 <sys_link+0xea>
  ip->nlink++;
    8000549e:	04a4d783          	lhu	a5,74(s1)
    800054a2:	2785                	addiw	a5,a5,1
    800054a4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054a8:	8526                	mv	a0,s1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	24e080e7          	jalr	590(ra) # 800036f8 <iupdate>
  iunlock(ip);
    800054b2:	8526                	mv	a0,s1
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	3d0080e7          	jalr	976(ra) # 80003884 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054bc:	fd040593          	addi	a1,s0,-48
    800054c0:	f5040513          	addi	a0,s0,-176
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	ac2080e7          	jalr	-1342(ra) # 80003f86 <nameiparent>
    800054cc:	892a                	mv	s2,a0
    800054ce:	c935                	beqz	a0,80005542 <sys_link+0x10a>
  ilock(dp);
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	2f2080e7          	jalr	754(ra) # 800037c2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054d8:	00092703          	lw	a4,0(s2)
    800054dc:	409c                	lw	a5,0(s1)
    800054de:	04f71d63          	bne	a4,a5,80005538 <sys_link+0x100>
    800054e2:	40d0                	lw	a2,4(s1)
    800054e4:	fd040593          	addi	a1,s0,-48
    800054e8:	854a                	mv	a0,s2
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	9cc080e7          	jalr	-1588(ra) # 80003eb6 <dirlink>
    800054f2:	04054363          	bltz	a0,80005538 <sys_link+0x100>
  iunlockput(dp);
    800054f6:	854a                	mv	a0,s2
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	52c080e7          	jalr	1324(ra) # 80003a24 <iunlockput>
  iput(ip);
    80005500:	8526                	mv	a0,s1
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	47a080e7          	jalr	1146(ra) # 8000397c <iput>
  end_op();
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	cfa080e7          	jalr	-774(ra) # 80004204 <end_op>
  return 0;
    80005512:	4781                	li	a5,0
    80005514:	a085                	j	80005574 <sys_link+0x13c>
    end_op();
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	cee080e7          	jalr	-786(ra) # 80004204 <end_op>
    return -1;
    8000551e:	57fd                	li	a5,-1
    80005520:	a891                	j	80005574 <sys_link+0x13c>
    iunlockput(ip);
    80005522:	8526                	mv	a0,s1
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	500080e7          	jalr	1280(ra) # 80003a24 <iunlockput>
    end_op();
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	cd8080e7          	jalr	-808(ra) # 80004204 <end_op>
    return -1;
    80005534:	57fd                	li	a5,-1
    80005536:	a83d                	j	80005574 <sys_link+0x13c>
    iunlockput(dp);
    80005538:	854a                	mv	a0,s2
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	4ea080e7          	jalr	1258(ra) # 80003a24 <iunlockput>
  ilock(ip);
    80005542:	8526                	mv	a0,s1
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	27e080e7          	jalr	638(ra) # 800037c2 <ilock>
  ip->nlink--;
    8000554c:	04a4d783          	lhu	a5,74(s1)
    80005550:	37fd                	addiw	a5,a5,-1
    80005552:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005556:	8526                	mv	a0,s1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	1a0080e7          	jalr	416(ra) # 800036f8 <iupdate>
  iunlockput(ip);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	4c2080e7          	jalr	1218(ra) # 80003a24 <iunlockput>
  end_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	c9a080e7          	jalr	-870(ra) # 80004204 <end_op>
  return -1;
    80005572:	57fd                	li	a5,-1
}
    80005574:	853e                	mv	a0,a5
    80005576:	70b2                	ld	ra,296(sp)
    80005578:	7412                	ld	s0,288(sp)
    8000557a:	64f2                	ld	s1,280(sp)
    8000557c:	6952                	ld	s2,272(sp)
    8000557e:	6155                	addi	sp,sp,304
    80005580:	8082                	ret

0000000080005582 <sys_unlink>:
{
    80005582:	7151                	addi	sp,sp,-240
    80005584:	f586                	sd	ra,232(sp)
    80005586:	f1a2                	sd	s0,224(sp)
    80005588:	eda6                	sd	s1,216(sp)
    8000558a:	e9ca                	sd	s2,208(sp)
    8000558c:	e5ce                	sd	s3,200(sp)
    8000558e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005590:	08000613          	li	a2,128
    80005594:	f3040593          	addi	a1,s0,-208
    80005598:	4501                	li	a0,0
    8000559a:	ffffd097          	auipc	ra,0xffffd
    8000559e:	6ba080e7          	jalr	1722(ra) # 80002c54 <argstr>
    800055a2:	18054163          	bltz	a0,80005724 <sys_unlink+0x1a2>
  begin_op();
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	bde080e7          	jalr	-1058(ra) # 80004184 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055ae:	fb040593          	addi	a1,s0,-80
    800055b2:	f3040513          	addi	a0,s0,-208
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	9d0080e7          	jalr	-1584(ra) # 80003f86 <nameiparent>
    800055be:	84aa                	mv	s1,a0
    800055c0:	c979                	beqz	a0,80005696 <sys_unlink+0x114>
  ilock(dp);
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	200080e7          	jalr	512(ra) # 800037c2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055ca:	00003597          	auipc	a1,0x3
    800055ce:	15658593          	addi	a1,a1,342 # 80008720 <syscalls+0x2b0>
    800055d2:	fb040513          	addi	a0,s0,-80
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	6b6080e7          	jalr	1718(ra) # 80003c8c <namecmp>
    800055de:	14050a63          	beqz	a0,80005732 <sys_unlink+0x1b0>
    800055e2:	00003597          	auipc	a1,0x3
    800055e6:	14658593          	addi	a1,a1,326 # 80008728 <syscalls+0x2b8>
    800055ea:	fb040513          	addi	a0,s0,-80
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	69e080e7          	jalr	1694(ra) # 80003c8c <namecmp>
    800055f6:	12050e63          	beqz	a0,80005732 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055fa:	f2c40613          	addi	a2,s0,-212
    800055fe:	fb040593          	addi	a1,s0,-80
    80005602:	8526                	mv	a0,s1
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	6a2080e7          	jalr	1698(ra) # 80003ca6 <dirlookup>
    8000560c:	892a                	mv	s2,a0
    8000560e:	12050263          	beqz	a0,80005732 <sys_unlink+0x1b0>
  ilock(ip);
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	1b0080e7          	jalr	432(ra) # 800037c2 <ilock>
  if(ip->nlink < 1)
    8000561a:	04a91783          	lh	a5,74(s2)
    8000561e:	08f05263          	blez	a5,800056a2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005622:	04491703          	lh	a4,68(s2)
    80005626:	4785                	li	a5,1
    80005628:	08f70563          	beq	a4,a5,800056b2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000562c:	4641                	li	a2,16
    8000562e:	4581                	li	a1,0
    80005630:	fc040513          	addi	a0,s0,-64
    80005634:	ffffb097          	auipc	ra,0xffffb
    80005638:	6b2080e7          	jalr	1714(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000563c:	4741                	li	a4,16
    8000563e:	f2c42683          	lw	a3,-212(s0)
    80005642:	fc040613          	addi	a2,s0,-64
    80005646:	4581                	li	a1,0
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	524080e7          	jalr	1316(ra) # 80003b6e <writei>
    80005652:	47c1                	li	a5,16
    80005654:	0af51563          	bne	a0,a5,800056fe <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005658:	04491703          	lh	a4,68(s2)
    8000565c:	4785                	li	a5,1
    8000565e:	0af70863          	beq	a4,a5,8000570e <sys_unlink+0x18c>
  iunlockput(dp);
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	3c0080e7          	jalr	960(ra) # 80003a24 <iunlockput>
  ip->nlink--;
    8000566c:	04a95783          	lhu	a5,74(s2)
    80005670:	37fd                	addiw	a5,a5,-1
    80005672:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005676:	854a                	mv	a0,s2
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	080080e7          	jalr	128(ra) # 800036f8 <iupdate>
  iunlockput(ip);
    80005680:	854a                	mv	a0,s2
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	3a2080e7          	jalr	930(ra) # 80003a24 <iunlockput>
  end_op();
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	b7a080e7          	jalr	-1158(ra) # 80004204 <end_op>
  return 0;
    80005692:	4501                	li	a0,0
    80005694:	a84d                	j	80005746 <sys_unlink+0x1c4>
    end_op();
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	b6e080e7          	jalr	-1170(ra) # 80004204 <end_op>
    return -1;
    8000569e:	557d                	li	a0,-1
    800056a0:	a05d                	j	80005746 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056a2:	00003517          	auipc	a0,0x3
    800056a6:	08e50513          	addi	a0,a0,142 # 80008730 <syscalls+0x2c0>
    800056aa:	ffffb097          	auipc	ra,0xffffb
    800056ae:	e9a080e7          	jalr	-358(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b2:	04c92703          	lw	a4,76(s2)
    800056b6:	02000793          	li	a5,32
    800056ba:	f6e7f9e3          	bgeu	a5,a4,8000562c <sys_unlink+0xaa>
    800056be:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056c2:	4741                	li	a4,16
    800056c4:	86ce                	mv	a3,s3
    800056c6:	f1840613          	addi	a2,s0,-232
    800056ca:	4581                	li	a1,0
    800056cc:	854a                	mv	a0,s2
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	3a8080e7          	jalr	936(ra) # 80003a76 <readi>
    800056d6:	47c1                	li	a5,16
    800056d8:	00f51b63          	bne	a0,a5,800056ee <sys_unlink+0x16c>
    if(de.inum != 0)
    800056dc:	f1845783          	lhu	a5,-232(s0)
    800056e0:	e7a1                	bnez	a5,80005728 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056e2:	29c1                	addiw	s3,s3,16
    800056e4:	04c92783          	lw	a5,76(s2)
    800056e8:	fcf9ede3          	bltu	s3,a5,800056c2 <sys_unlink+0x140>
    800056ec:	b781                	j	8000562c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056ee:	00003517          	auipc	a0,0x3
    800056f2:	05a50513          	addi	a0,a0,90 # 80008748 <syscalls+0x2d8>
    800056f6:	ffffb097          	auipc	ra,0xffffb
    800056fa:	e4e080e7          	jalr	-434(ra) # 80000544 <panic>
    panic("unlink: writei");
    800056fe:	00003517          	auipc	a0,0x3
    80005702:	06250513          	addi	a0,a0,98 # 80008760 <syscalls+0x2f0>
    80005706:	ffffb097          	auipc	ra,0xffffb
    8000570a:	e3e080e7          	jalr	-450(ra) # 80000544 <panic>
    dp->nlink--;
    8000570e:	04a4d783          	lhu	a5,74(s1)
    80005712:	37fd                	addiw	a5,a5,-1
    80005714:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005718:	8526                	mv	a0,s1
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	fde080e7          	jalr	-34(ra) # 800036f8 <iupdate>
    80005722:	b781                	j	80005662 <sys_unlink+0xe0>
    return -1;
    80005724:	557d                	li	a0,-1
    80005726:	a005                	j	80005746 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005728:	854a                	mv	a0,s2
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	2fa080e7          	jalr	762(ra) # 80003a24 <iunlockput>
  iunlockput(dp);
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	2f0080e7          	jalr	752(ra) # 80003a24 <iunlockput>
  end_op();
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	ac8080e7          	jalr	-1336(ra) # 80004204 <end_op>
  return -1;
    80005744:	557d                	li	a0,-1
}
    80005746:	70ae                	ld	ra,232(sp)
    80005748:	740e                	ld	s0,224(sp)
    8000574a:	64ee                	ld	s1,216(sp)
    8000574c:	694e                	ld	s2,208(sp)
    8000574e:	69ae                	ld	s3,200(sp)
    80005750:	616d                	addi	sp,sp,240
    80005752:	8082                	ret

0000000080005754 <sys_open>:

uint64
sys_open(void)
{
    80005754:	7131                	addi	sp,sp,-192
    80005756:	fd06                	sd	ra,184(sp)
    80005758:	f922                	sd	s0,176(sp)
    8000575a:	f526                	sd	s1,168(sp)
    8000575c:	f14a                	sd	s2,160(sp)
    8000575e:	ed4e                	sd	s3,152(sp)
    80005760:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005762:	f4c40593          	addi	a1,s0,-180
    80005766:	4505                	li	a0,1
    80005768:	ffffd097          	auipc	ra,0xffffd
    8000576c:	4ac080e7          	jalr	1196(ra) # 80002c14 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005770:	08000613          	li	a2,128
    80005774:	f5040593          	addi	a1,s0,-176
    80005778:	4501                	li	a0,0
    8000577a:	ffffd097          	auipc	ra,0xffffd
    8000577e:	4da080e7          	jalr	1242(ra) # 80002c54 <argstr>
    80005782:	87aa                	mv	a5,a0
    return -1;
    80005784:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005786:	0a07c963          	bltz	a5,80005838 <sys_open+0xe4>

  begin_op();
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	9fa080e7          	jalr	-1542(ra) # 80004184 <begin_op>

  if(omode & O_CREATE){
    80005792:	f4c42783          	lw	a5,-180(s0)
    80005796:	2007f793          	andi	a5,a5,512
    8000579a:	cfc5                	beqz	a5,80005852 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000579c:	4681                	li	a3,0
    8000579e:	4601                	li	a2,0
    800057a0:	4589                	li	a1,2
    800057a2:	f5040513          	addi	a0,s0,-176
    800057a6:	00000097          	auipc	ra,0x0
    800057aa:	974080e7          	jalr	-1676(ra) # 8000511a <create>
    800057ae:	84aa                	mv	s1,a0
    if(ip == 0){
    800057b0:	c959                	beqz	a0,80005846 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057b2:	04449703          	lh	a4,68(s1)
    800057b6:	478d                	li	a5,3
    800057b8:	00f71763          	bne	a4,a5,800057c6 <sys_open+0x72>
    800057bc:	0464d703          	lhu	a4,70(s1)
    800057c0:	47a5                	li	a5,9
    800057c2:	0ce7ed63          	bltu	a5,a4,8000589c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	dce080e7          	jalr	-562(ra) # 80004594 <filealloc>
    800057ce:	89aa                	mv	s3,a0
    800057d0:	10050363          	beqz	a0,800058d6 <sys_open+0x182>
    800057d4:	00000097          	auipc	ra,0x0
    800057d8:	904080e7          	jalr	-1788(ra) # 800050d8 <fdalloc>
    800057dc:	892a                	mv	s2,a0
    800057de:	0e054763          	bltz	a0,800058cc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057e2:	04449703          	lh	a4,68(s1)
    800057e6:	478d                	li	a5,3
    800057e8:	0cf70563          	beq	a4,a5,800058b2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057ec:	4789                	li	a5,2
    800057ee:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057f2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057f6:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057fa:	f4c42783          	lw	a5,-180(s0)
    800057fe:	0017c713          	xori	a4,a5,1
    80005802:	8b05                	andi	a4,a4,1
    80005804:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005808:	0037f713          	andi	a4,a5,3
    8000580c:	00e03733          	snez	a4,a4
    80005810:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005814:	4007f793          	andi	a5,a5,1024
    80005818:	c791                	beqz	a5,80005824 <sys_open+0xd0>
    8000581a:	04449703          	lh	a4,68(s1)
    8000581e:	4789                	li	a5,2
    80005820:	0af70063          	beq	a4,a5,800058c0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	05e080e7          	jalr	94(ra) # 80003884 <iunlock>
  end_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	9d6080e7          	jalr	-1578(ra) # 80004204 <end_op>

  return fd;
    80005836:	854a                	mv	a0,s2
}
    80005838:	70ea                	ld	ra,184(sp)
    8000583a:	744a                	ld	s0,176(sp)
    8000583c:	74aa                	ld	s1,168(sp)
    8000583e:	790a                	ld	s2,160(sp)
    80005840:	69ea                	ld	s3,152(sp)
    80005842:	6129                	addi	sp,sp,192
    80005844:	8082                	ret
      end_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	9be080e7          	jalr	-1602(ra) # 80004204 <end_op>
      return -1;
    8000584e:	557d                	li	a0,-1
    80005850:	b7e5                	j	80005838 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005852:	f5040513          	addi	a0,s0,-176
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	712080e7          	jalr	1810(ra) # 80003f68 <namei>
    8000585e:	84aa                	mv	s1,a0
    80005860:	c905                	beqz	a0,80005890 <sys_open+0x13c>
    ilock(ip);
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	f60080e7          	jalr	-160(ra) # 800037c2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000586a:	04449703          	lh	a4,68(s1)
    8000586e:	4785                	li	a5,1
    80005870:	f4f711e3          	bne	a4,a5,800057b2 <sys_open+0x5e>
    80005874:	f4c42783          	lw	a5,-180(s0)
    80005878:	d7b9                	beqz	a5,800057c6 <sys_open+0x72>
      iunlockput(ip);
    8000587a:	8526                	mv	a0,s1
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	1a8080e7          	jalr	424(ra) # 80003a24 <iunlockput>
      end_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	980080e7          	jalr	-1664(ra) # 80004204 <end_op>
      return -1;
    8000588c:	557d                	li	a0,-1
    8000588e:	b76d                	j	80005838 <sys_open+0xe4>
      end_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	974080e7          	jalr	-1676(ra) # 80004204 <end_op>
      return -1;
    80005898:	557d                	li	a0,-1
    8000589a:	bf79                	j	80005838 <sys_open+0xe4>
    iunlockput(ip);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	186080e7          	jalr	390(ra) # 80003a24 <iunlockput>
    end_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	95e080e7          	jalr	-1698(ra) # 80004204 <end_op>
    return -1;
    800058ae:	557d                	li	a0,-1
    800058b0:	b761                	j	80005838 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058b2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058b6:	04649783          	lh	a5,70(s1)
    800058ba:	02f99223          	sh	a5,36(s3)
    800058be:	bf25                	j	800057f6 <sys_open+0xa2>
    itrunc(ip);
    800058c0:	8526                	mv	a0,s1
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	00e080e7          	jalr	14(ra) # 800038d0 <itrunc>
    800058ca:	bfa9                	j	80005824 <sys_open+0xd0>
      fileclose(f);
    800058cc:	854e                	mv	a0,s3
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	d82080e7          	jalr	-638(ra) # 80004650 <fileclose>
    iunlockput(ip);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	14c080e7          	jalr	332(ra) # 80003a24 <iunlockput>
    end_op();
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	924080e7          	jalr	-1756(ra) # 80004204 <end_op>
    return -1;
    800058e8:	557d                	li	a0,-1
    800058ea:	b7b9                	j	80005838 <sys_open+0xe4>

00000000800058ec <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058ec:	7175                	addi	sp,sp,-144
    800058ee:	e506                	sd	ra,136(sp)
    800058f0:	e122                	sd	s0,128(sp)
    800058f2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	890080e7          	jalr	-1904(ra) # 80004184 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058fc:	08000613          	li	a2,128
    80005900:	f7040593          	addi	a1,s0,-144
    80005904:	4501                	li	a0,0
    80005906:	ffffd097          	auipc	ra,0xffffd
    8000590a:	34e080e7          	jalr	846(ra) # 80002c54 <argstr>
    8000590e:	02054963          	bltz	a0,80005940 <sys_mkdir+0x54>
    80005912:	4681                	li	a3,0
    80005914:	4601                	li	a2,0
    80005916:	4585                	li	a1,1
    80005918:	f7040513          	addi	a0,s0,-144
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	7fe080e7          	jalr	2046(ra) # 8000511a <create>
    80005924:	cd11                	beqz	a0,80005940 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	0fe080e7          	jalr	254(ra) # 80003a24 <iunlockput>
  end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	8d6080e7          	jalr	-1834(ra) # 80004204 <end_op>
  return 0;
    80005936:	4501                	li	a0,0
}
    80005938:	60aa                	ld	ra,136(sp)
    8000593a:	640a                	ld	s0,128(sp)
    8000593c:	6149                	addi	sp,sp,144
    8000593e:	8082                	ret
    end_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	8c4080e7          	jalr	-1852(ra) # 80004204 <end_op>
    return -1;
    80005948:	557d                	li	a0,-1
    8000594a:	b7fd                	j	80005938 <sys_mkdir+0x4c>

000000008000594c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000594c:	7135                	addi	sp,sp,-160
    8000594e:	ed06                	sd	ra,152(sp)
    80005950:	e922                	sd	s0,144(sp)
    80005952:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	830080e7          	jalr	-2000(ra) # 80004184 <begin_op>
  argint(1, &major);
    8000595c:	f6c40593          	addi	a1,s0,-148
    80005960:	4505                	li	a0,1
    80005962:	ffffd097          	auipc	ra,0xffffd
    80005966:	2b2080e7          	jalr	690(ra) # 80002c14 <argint>
  argint(2, &minor);
    8000596a:	f6840593          	addi	a1,s0,-152
    8000596e:	4509                	li	a0,2
    80005970:	ffffd097          	auipc	ra,0xffffd
    80005974:	2a4080e7          	jalr	676(ra) # 80002c14 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005978:	08000613          	li	a2,128
    8000597c:	f7040593          	addi	a1,s0,-144
    80005980:	4501                	li	a0,0
    80005982:	ffffd097          	auipc	ra,0xffffd
    80005986:	2d2080e7          	jalr	722(ra) # 80002c54 <argstr>
    8000598a:	02054b63          	bltz	a0,800059c0 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000598e:	f6841683          	lh	a3,-152(s0)
    80005992:	f6c41603          	lh	a2,-148(s0)
    80005996:	458d                	li	a1,3
    80005998:	f7040513          	addi	a0,s0,-144
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	77e080e7          	jalr	1918(ra) # 8000511a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a4:	cd11                	beqz	a0,800059c0 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	07e080e7          	jalr	126(ra) # 80003a24 <iunlockput>
  end_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	856080e7          	jalr	-1962(ra) # 80004204 <end_op>
  return 0;
    800059b6:	4501                	li	a0,0
}
    800059b8:	60ea                	ld	ra,152(sp)
    800059ba:	644a                	ld	s0,144(sp)
    800059bc:	610d                	addi	sp,sp,160
    800059be:	8082                	ret
    end_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	844080e7          	jalr	-1980(ra) # 80004204 <end_op>
    return -1;
    800059c8:	557d                	li	a0,-1
    800059ca:	b7fd                	j	800059b8 <sys_mknod+0x6c>

00000000800059cc <sys_chdir>:

uint64
sys_chdir(void)
{
    800059cc:	7135                	addi	sp,sp,-160
    800059ce:	ed06                	sd	ra,152(sp)
    800059d0:	e922                	sd	s0,144(sp)
    800059d2:	e526                	sd	s1,136(sp)
    800059d4:	e14a                	sd	s2,128(sp)
    800059d6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059d8:	ffffc097          	auipc	ra,0xffffc
    800059dc:	fee080e7          	jalr	-18(ra) # 800019c6 <myproc>
    800059e0:	892a                	mv	s2,a0
  
  begin_op();
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	7a2080e7          	jalr	1954(ra) # 80004184 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059ea:	08000613          	li	a2,128
    800059ee:	f6040593          	addi	a1,s0,-160
    800059f2:	4501                	li	a0,0
    800059f4:	ffffd097          	auipc	ra,0xffffd
    800059f8:	260080e7          	jalr	608(ra) # 80002c54 <argstr>
    800059fc:	04054b63          	bltz	a0,80005a52 <sys_chdir+0x86>
    80005a00:	f6040513          	addi	a0,s0,-160
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	564080e7          	jalr	1380(ra) # 80003f68 <namei>
    80005a0c:	84aa                	mv	s1,a0
    80005a0e:	c131                	beqz	a0,80005a52 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	db2080e7          	jalr	-590(ra) # 800037c2 <ilock>
  if(ip->type != T_DIR){
    80005a18:	04449703          	lh	a4,68(s1)
    80005a1c:	4785                	li	a5,1
    80005a1e:	04f71063          	bne	a4,a5,80005a5e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a22:	8526                	mv	a0,s1
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	e60080e7          	jalr	-416(ra) # 80003884 <iunlock>
  iput(p->cwd);
    80005a2c:	16093503          	ld	a0,352(s2)
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	f4c080e7          	jalr	-180(ra) # 8000397c <iput>
  end_op();
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	7cc080e7          	jalr	1996(ra) # 80004204 <end_op>
  p->cwd = ip;
    80005a40:	16993023          	sd	s1,352(s2)
  return 0;
    80005a44:	4501                	li	a0,0
}
    80005a46:	60ea                	ld	ra,152(sp)
    80005a48:	644a                	ld	s0,144(sp)
    80005a4a:	64aa                	ld	s1,136(sp)
    80005a4c:	690a                	ld	s2,128(sp)
    80005a4e:	610d                	addi	sp,sp,160
    80005a50:	8082                	ret
    end_op();
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	7b2080e7          	jalr	1970(ra) # 80004204 <end_op>
    return -1;
    80005a5a:	557d                	li	a0,-1
    80005a5c:	b7ed                	j	80005a46 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a5e:	8526                	mv	a0,s1
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	fc4080e7          	jalr	-60(ra) # 80003a24 <iunlockput>
    end_op();
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	79c080e7          	jalr	1948(ra) # 80004204 <end_op>
    return -1;
    80005a70:	557d                	li	a0,-1
    80005a72:	bfd1                	j	80005a46 <sys_chdir+0x7a>

0000000080005a74 <sys_exec>:

uint64
sys_exec(void)
{
    80005a74:	7145                	addi	sp,sp,-464
    80005a76:	e786                	sd	ra,456(sp)
    80005a78:	e3a2                	sd	s0,448(sp)
    80005a7a:	ff26                	sd	s1,440(sp)
    80005a7c:	fb4a                	sd	s2,432(sp)
    80005a7e:	f74e                	sd	s3,424(sp)
    80005a80:	f352                	sd	s4,416(sp)
    80005a82:	ef56                	sd	s5,408(sp)
    80005a84:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a86:	e3840593          	addi	a1,s0,-456
    80005a8a:	4505                	li	a0,1
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	1a8080e7          	jalr	424(ra) # 80002c34 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a94:	08000613          	li	a2,128
    80005a98:	f4040593          	addi	a1,s0,-192
    80005a9c:	4501                	li	a0,0
    80005a9e:	ffffd097          	auipc	ra,0xffffd
    80005aa2:	1b6080e7          	jalr	438(ra) # 80002c54 <argstr>
    80005aa6:	87aa                	mv	a5,a0
    return -1;
    80005aa8:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005aaa:	0c07c263          	bltz	a5,80005b6e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005aae:	10000613          	li	a2,256
    80005ab2:	4581                	li	a1,0
    80005ab4:	e4040513          	addi	a0,s0,-448
    80005ab8:	ffffb097          	auipc	ra,0xffffb
    80005abc:	22e080e7          	jalr	558(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ac0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ac4:	89a6                	mv	s3,s1
    80005ac6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ac8:	02000a13          	li	s4,32
    80005acc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ad0:	00391513          	slli	a0,s2,0x3
    80005ad4:	e3040593          	addi	a1,s0,-464
    80005ad8:	e3843783          	ld	a5,-456(s0)
    80005adc:	953e                	add	a0,a0,a5
    80005ade:	ffffd097          	auipc	ra,0xffffd
    80005ae2:	098080e7          	jalr	152(ra) # 80002b76 <fetchaddr>
    80005ae6:	02054a63          	bltz	a0,80005b1a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005aea:	e3043783          	ld	a5,-464(s0)
    80005aee:	c3b9                	beqz	a5,80005b34 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005af0:	ffffb097          	auipc	ra,0xffffb
    80005af4:	00a080e7          	jalr	10(ra) # 80000afa <kalloc>
    80005af8:	85aa                	mv	a1,a0
    80005afa:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005afe:	cd11                	beqz	a0,80005b1a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b00:	6605                	lui	a2,0x1
    80005b02:	e3043503          	ld	a0,-464(s0)
    80005b06:	ffffd097          	auipc	ra,0xffffd
    80005b0a:	0c2080e7          	jalr	194(ra) # 80002bc8 <fetchstr>
    80005b0e:	00054663          	bltz	a0,80005b1a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b12:	0905                	addi	s2,s2,1
    80005b14:	09a1                	addi	s3,s3,8
    80005b16:	fb491be3          	bne	s2,s4,80005acc <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1a:	10048913          	addi	s2,s1,256
    80005b1e:	6088                	ld	a0,0(s1)
    80005b20:	c531                	beqz	a0,80005b6c <sys_exec+0xf8>
    kfree(argv[i]);
    80005b22:	ffffb097          	auipc	ra,0xffffb
    80005b26:	edc080e7          	jalr	-292(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2a:	04a1                	addi	s1,s1,8
    80005b2c:	ff2499e3          	bne	s1,s2,80005b1e <sys_exec+0xaa>
  return -1;
    80005b30:	557d                	li	a0,-1
    80005b32:	a835                	j	80005b6e <sys_exec+0xfa>
      argv[i] = 0;
    80005b34:	0a8e                	slli	s5,s5,0x3
    80005b36:	fc040793          	addi	a5,s0,-64
    80005b3a:	9abe                	add	s5,s5,a5
    80005b3c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b40:	e4040593          	addi	a1,s0,-448
    80005b44:	f4040513          	addi	a0,s0,-192
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	190080e7          	jalr	400(ra) # 80004cd8 <exec>
    80005b50:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b52:	10048993          	addi	s3,s1,256
    80005b56:	6088                	ld	a0,0(s1)
    80005b58:	c901                	beqz	a0,80005b68 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b5a:	ffffb097          	auipc	ra,0xffffb
    80005b5e:	ea4080e7          	jalr	-348(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b62:	04a1                	addi	s1,s1,8
    80005b64:	ff3499e3          	bne	s1,s3,80005b56 <sys_exec+0xe2>
  return ret;
    80005b68:	854a                	mv	a0,s2
    80005b6a:	a011                	j	80005b6e <sys_exec+0xfa>
  return -1;
    80005b6c:	557d                	li	a0,-1
}
    80005b6e:	60be                	ld	ra,456(sp)
    80005b70:	641e                	ld	s0,448(sp)
    80005b72:	74fa                	ld	s1,440(sp)
    80005b74:	795a                	ld	s2,432(sp)
    80005b76:	79ba                	ld	s3,424(sp)
    80005b78:	7a1a                	ld	s4,416(sp)
    80005b7a:	6afa                	ld	s5,408(sp)
    80005b7c:	6179                	addi	sp,sp,464
    80005b7e:	8082                	ret

0000000080005b80 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b80:	7139                	addi	sp,sp,-64
    80005b82:	fc06                	sd	ra,56(sp)
    80005b84:	f822                	sd	s0,48(sp)
    80005b86:	f426                	sd	s1,40(sp)
    80005b88:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b8a:	ffffc097          	auipc	ra,0xffffc
    80005b8e:	e3c080e7          	jalr	-452(ra) # 800019c6 <myproc>
    80005b92:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b94:	fd840593          	addi	a1,s0,-40
    80005b98:	4501                	li	a0,0
    80005b9a:	ffffd097          	auipc	ra,0xffffd
    80005b9e:	09a080e7          	jalr	154(ra) # 80002c34 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ba2:	fc840593          	addi	a1,s0,-56
    80005ba6:	fd040513          	addi	a0,s0,-48
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	dd6080e7          	jalr	-554(ra) # 80004980 <pipealloc>
    return -1;
    80005bb2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bb4:	0c054463          	bltz	a0,80005c7c <sys_pipe+0xfc>
  fd0 = -1;
    80005bb8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bbc:	fd043503          	ld	a0,-48(s0)
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	518080e7          	jalr	1304(ra) # 800050d8 <fdalloc>
    80005bc8:	fca42223          	sw	a0,-60(s0)
    80005bcc:	08054b63          	bltz	a0,80005c62 <sys_pipe+0xe2>
    80005bd0:	fc843503          	ld	a0,-56(s0)
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	504080e7          	jalr	1284(ra) # 800050d8 <fdalloc>
    80005bdc:	fca42023          	sw	a0,-64(s0)
    80005be0:	06054863          	bltz	a0,80005c50 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005be4:	4691                	li	a3,4
    80005be6:	fc440613          	addi	a2,s0,-60
    80005bea:	fd843583          	ld	a1,-40(s0)
    80005bee:	70a8                	ld	a0,96(s1)
    80005bf0:	ffffc097          	auipc	ra,0xffffc
    80005bf4:	a94080e7          	jalr	-1388(ra) # 80001684 <copyout>
    80005bf8:	02054063          	bltz	a0,80005c18 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bfc:	4691                	li	a3,4
    80005bfe:	fc040613          	addi	a2,s0,-64
    80005c02:	fd843583          	ld	a1,-40(s0)
    80005c06:	0591                	addi	a1,a1,4
    80005c08:	70a8                	ld	a0,96(s1)
    80005c0a:	ffffc097          	auipc	ra,0xffffc
    80005c0e:	a7a080e7          	jalr	-1414(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c12:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c14:	06055463          	bgez	a0,80005c7c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c18:	fc442783          	lw	a5,-60(s0)
    80005c1c:	07f1                	addi	a5,a5,28
    80005c1e:	078e                	slli	a5,a5,0x3
    80005c20:	97a6                	add	a5,a5,s1
    80005c22:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c26:	fc042503          	lw	a0,-64(s0)
    80005c2a:	0571                	addi	a0,a0,28
    80005c2c:	050e                	slli	a0,a0,0x3
    80005c2e:	94aa                	add	s1,s1,a0
    80005c30:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c34:	fd043503          	ld	a0,-48(s0)
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	a18080e7          	jalr	-1512(ra) # 80004650 <fileclose>
    fileclose(wf);
    80005c40:	fc843503          	ld	a0,-56(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	a0c080e7          	jalr	-1524(ra) # 80004650 <fileclose>
    return -1;
    80005c4c:	57fd                	li	a5,-1
    80005c4e:	a03d                	j	80005c7c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c50:	fc442783          	lw	a5,-60(s0)
    80005c54:	0007c763          	bltz	a5,80005c62 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c58:	07f1                	addi	a5,a5,28
    80005c5a:	078e                	slli	a5,a5,0x3
    80005c5c:	94be                	add	s1,s1,a5
    80005c5e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c62:	fd043503          	ld	a0,-48(s0)
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	9ea080e7          	jalr	-1558(ra) # 80004650 <fileclose>
    fileclose(wf);
    80005c6e:	fc843503          	ld	a0,-56(s0)
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	9de080e7          	jalr	-1570(ra) # 80004650 <fileclose>
    return -1;
    80005c7a:	57fd                	li	a5,-1
}
    80005c7c:	853e                	mv	a0,a5
    80005c7e:	70e2                	ld	ra,56(sp)
    80005c80:	7442                	ld	s0,48(sp)
    80005c82:	74a2                	ld	s1,40(sp)
    80005c84:	6121                	addi	sp,sp,64
    80005c86:	8082                	ret
	...

0000000080005c90 <kernelvec>:
    80005c90:	7111                	addi	sp,sp,-256
    80005c92:	e006                	sd	ra,0(sp)
    80005c94:	e40a                	sd	sp,8(sp)
    80005c96:	e80e                	sd	gp,16(sp)
    80005c98:	ec12                	sd	tp,24(sp)
    80005c9a:	f016                	sd	t0,32(sp)
    80005c9c:	f41a                	sd	t1,40(sp)
    80005c9e:	f81e                	sd	t2,48(sp)
    80005ca0:	fc22                	sd	s0,56(sp)
    80005ca2:	e0a6                	sd	s1,64(sp)
    80005ca4:	e4aa                	sd	a0,72(sp)
    80005ca6:	e8ae                	sd	a1,80(sp)
    80005ca8:	ecb2                	sd	a2,88(sp)
    80005caa:	f0b6                	sd	a3,96(sp)
    80005cac:	f4ba                	sd	a4,104(sp)
    80005cae:	f8be                	sd	a5,112(sp)
    80005cb0:	fcc2                	sd	a6,120(sp)
    80005cb2:	e146                	sd	a7,128(sp)
    80005cb4:	e54a                	sd	s2,136(sp)
    80005cb6:	e94e                	sd	s3,144(sp)
    80005cb8:	ed52                	sd	s4,152(sp)
    80005cba:	f156                	sd	s5,160(sp)
    80005cbc:	f55a                	sd	s6,168(sp)
    80005cbe:	f95e                	sd	s7,176(sp)
    80005cc0:	fd62                	sd	s8,184(sp)
    80005cc2:	e1e6                	sd	s9,192(sp)
    80005cc4:	e5ea                	sd	s10,200(sp)
    80005cc6:	e9ee                	sd	s11,208(sp)
    80005cc8:	edf2                	sd	t3,216(sp)
    80005cca:	f1f6                	sd	t4,224(sp)
    80005ccc:	f5fa                	sd	t5,232(sp)
    80005cce:	f9fe                	sd	t6,240(sp)
    80005cd0:	d73fc0ef          	jal	ra,80002a42 <kerneltrap>
    80005cd4:	6082                	ld	ra,0(sp)
    80005cd6:	6122                	ld	sp,8(sp)
    80005cd8:	61c2                	ld	gp,16(sp)
    80005cda:	7282                	ld	t0,32(sp)
    80005cdc:	7322                	ld	t1,40(sp)
    80005cde:	73c2                	ld	t2,48(sp)
    80005ce0:	7462                	ld	s0,56(sp)
    80005ce2:	6486                	ld	s1,64(sp)
    80005ce4:	6526                	ld	a0,72(sp)
    80005ce6:	65c6                	ld	a1,80(sp)
    80005ce8:	6666                	ld	a2,88(sp)
    80005cea:	7686                	ld	a3,96(sp)
    80005cec:	7726                	ld	a4,104(sp)
    80005cee:	77c6                	ld	a5,112(sp)
    80005cf0:	7866                	ld	a6,120(sp)
    80005cf2:	688a                	ld	a7,128(sp)
    80005cf4:	692a                	ld	s2,136(sp)
    80005cf6:	69ca                	ld	s3,144(sp)
    80005cf8:	6a6a                	ld	s4,152(sp)
    80005cfa:	7a8a                	ld	s5,160(sp)
    80005cfc:	7b2a                	ld	s6,168(sp)
    80005cfe:	7bca                	ld	s7,176(sp)
    80005d00:	7c6a                	ld	s8,184(sp)
    80005d02:	6c8e                	ld	s9,192(sp)
    80005d04:	6d2e                	ld	s10,200(sp)
    80005d06:	6dce                	ld	s11,208(sp)
    80005d08:	6e6e                	ld	t3,216(sp)
    80005d0a:	7e8e                	ld	t4,224(sp)
    80005d0c:	7f2e                	ld	t5,232(sp)
    80005d0e:	7fce                	ld	t6,240(sp)
    80005d10:	6111                	addi	sp,sp,256
    80005d12:	10200073          	sret
    80005d16:	00000013          	nop
    80005d1a:	00000013          	nop
    80005d1e:	0001                	nop

0000000080005d20 <timervec>:
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	e10c                	sd	a1,0(a0)
    80005d26:	e510                	sd	a2,8(a0)
    80005d28:	e914                	sd	a3,16(a0)
    80005d2a:	6d0c                	ld	a1,24(a0)
    80005d2c:	7110                	ld	a2,32(a0)
    80005d2e:	6194                	ld	a3,0(a1)
    80005d30:	96b2                	add	a3,a3,a2
    80005d32:	e194                	sd	a3,0(a1)
    80005d34:	4589                	li	a1,2
    80005d36:	14459073          	csrw	sip,a1
    80005d3a:	6914                	ld	a3,16(a0)
    80005d3c:	6510                	ld	a2,8(a0)
    80005d3e:	610c                	ld	a1,0(a0)
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	30200073          	mret
	...

0000000080005d4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d4a:	1141                	addi	sp,sp,-16
    80005d4c:	e422                	sd	s0,8(sp)
    80005d4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d50:	0c0007b7          	lui	a5,0xc000
    80005d54:	4705                	li	a4,1
    80005d56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d58:	c3d8                	sw	a4,4(a5)
}
    80005d5a:	6422                	ld	s0,8(sp)
    80005d5c:	0141                	addi	sp,sp,16
    80005d5e:	8082                	ret

0000000080005d60 <plicinithart>:

void
plicinithart(void)
{
    80005d60:	1141                	addi	sp,sp,-16
    80005d62:	e406                	sd	ra,8(sp)
    80005d64:	e022                	sd	s0,0(sp)
    80005d66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	c32080e7          	jalr	-974(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d70:	0085171b          	slliw	a4,a0,0x8
    80005d74:	0c0027b7          	lui	a5,0xc002
    80005d78:	97ba                	add	a5,a5,a4
    80005d7a:	40200713          	li	a4,1026
    80005d7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d82:	00d5151b          	slliw	a0,a0,0xd
    80005d86:	0c2017b7          	lui	a5,0xc201
    80005d8a:	953e                	add	a0,a0,a5
    80005d8c:	00052023          	sw	zero,0(a0)
}
    80005d90:	60a2                	ld	ra,8(sp)
    80005d92:	6402                	ld	s0,0(sp)
    80005d94:	0141                	addi	sp,sp,16
    80005d96:	8082                	ret

0000000080005d98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d98:	1141                	addi	sp,sp,-16
    80005d9a:	e406                	sd	ra,8(sp)
    80005d9c:	e022                	sd	s0,0(sp)
    80005d9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005da0:	ffffc097          	auipc	ra,0xffffc
    80005da4:	bfa080e7          	jalr	-1030(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005da8:	00d5179b          	slliw	a5,a0,0xd
    80005dac:	0c201537          	lui	a0,0xc201
    80005db0:	953e                	add	a0,a0,a5
  return irq;
}
    80005db2:	4148                	lw	a0,4(a0)
    80005db4:	60a2                	ld	ra,8(sp)
    80005db6:	6402                	ld	s0,0(sp)
    80005db8:	0141                	addi	sp,sp,16
    80005dba:	8082                	ret

0000000080005dbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dbc:	1101                	addi	sp,sp,-32
    80005dbe:	ec06                	sd	ra,24(sp)
    80005dc0:	e822                	sd	s0,16(sp)
    80005dc2:	e426                	sd	s1,8(sp)
    80005dc4:	1000                	addi	s0,sp,32
    80005dc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	bd2080e7          	jalr	-1070(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dd0:	00d5151b          	slliw	a0,a0,0xd
    80005dd4:	0c2017b7          	lui	a5,0xc201
    80005dd8:	97aa                	add	a5,a5,a0
    80005dda:	c3c4                	sw	s1,4(a5)
}
    80005ddc:	60e2                	ld	ra,24(sp)
    80005dde:	6442                	ld	s0,16(sp)
    80005de0:	64a2                	ld	s1,8(sp)
    80005de2:	6105                	addi	sp,sp,32
    80005de4:	8082                	ret

0000000080005de6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005de6:	1141                	addi	sp,sp,-16
    80005de8:	e406                	sd	ra,8(sp)
    80005dea:	e022                	sd	s0,0(sp)
    80005dec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dee:	479d                	li	a5,7
    80005df0:	04a7cc63          	blt	a5,a0,80005e48 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005df4:	0001c797          	auipc	a5,0x1c
    80005df8:	25c78793          	addi	a5,a5,604 # 80022050 <disk>
    80005dfc:	97aa                	add	a5,a5,a0
    80005dfe:	0187c783          	lbu	a5,24(a5)
    80005e02:	ebb9                	bnez	a5,80005e58 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e04:	00451613          	slli	a2,a0,0x4
    80005e08:	0001c797          	auipc	a5,0x1c
    80005e0c:	24878793          	addi	a5,a5,584 # 80022050 <disk>
    80005e10:	6394                	ld	a3,0(a5)
    80005e12:	96b2                	add	a3,a3,a2
    80005e14:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e18:	6398                	ld	a4,0(a5)
    80005e1a:	9732                	add	a4,a4,a2
    80005e1c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e20:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e24:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e28:	953e                	add	a0,a0,a5
    80005e2a:	4785                	li	a5,1
    80005e2c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e30:	0001c517          	auipc	a0,0x1c
    80005e34:	23850513          	addi	a0,a0,568 # 80022068 <disk+0x18>
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	318080e7          	jalr	792(ra) # 80002150 <wakeup>
}
    80005e40:	60a2                	ld	ra,8(sp)
    80005e42:	6402                	ld	s0,0(sp)
    80005e44:	0141                	addi	sp,sp,16
    80005e46:	8082                	ret
    panic("free_desc 1");
    80005e48:	00003517          	auipc	a0,0x3
    80005e4c:	92850513          	addi	a0,a0,-1752 # 80008770 <syscalls+0x300>
    80005e50:	ffffa097          	auipc	ra,0xffffa
    80005e54:	6f4080e7          	jalr	1780(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005e58:	00003517          	auipc	a0,0x3
    80005e5c:	92850513          	addi	a0,a0,-1752 # 80008780 <syscalls+0x310>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6e4080e7          	jalr	1764(ra) # 80000544 <panic>

0000000080005e68 <virtio_disk_init>:
{
    80005e68:	1101                	addi	sp,sp,-32
    80005e6a:	ec06                	sd	ra,24(sp)
    80005e6c:	e822                	sd	s0,16(sp)
    80005e6e:	e426                	sd	s1,8(sp)
    80005e70:	e04a                	sd	s2,0(sp)
    80005e72:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e74:	00003597          	auipc	a1,0x3
    80005e78:	91c58593          	addi	a1,a1,-1764 # 80008790 <syscalls+0x320>
    80005e7c:	0001c517          	auipc	a0,0x1c
    80005e80:	2fc50513          	addi	a0,a0,764 # 80022178 <disk+0x128>
    80005e84:	ffffb097          	auipc	ra,0xffffb
    80005e88:	cd6080e7          	jalr	-810(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	4398                	lw	a4,0(a5)
    80005e92:	2701                	sext.w	a4,a4
    80005e94:	747277b7          	lui	a5,0x74727
    80005e98:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e9c:	14f71e63          	bne	a4,a5,80005ff8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ea0:	100017b7          	lui	a5,0x10001
    80005ea4:	43dc                	lw	a5,4(a5)
    80005ea6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ea8:	4709                	li	a4,2
    80005eaa:	14e79763          	bne	a5,a4,80005ff8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	479c                	lw	a5,8(a5)
    80005eb4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005eb6:	14e79163          	bne	a5,a4,80005ff8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eba:	100017b7          	lui	a5,0x10001
    80005ebe:	47d8                	lw	a4,12(a5)
    80005ec0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ec2:	554d47b7          	lui	a5,0x554d4
    80005ec6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eca:	12f71763          	bne	a4,a5,80005ff8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed6:	4705                	li	a4,1
    80005ed8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eda:	470d                	li	a4,3
    80005edc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ede:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ee0:	c7ffe737          	lui	a4,0xc7ffe
    80005ee4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc5cf>
    80005ee8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005eea:	2701                	sext.w	a4,a4
    80005eec:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eee:	472d                	li	a4,11
    80005ef0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ef2:	0707a903          	lw	s2,112(a5)
    80005ef6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ef8:	00897793          	andi	a5,s2,8
    80005efc:	10078663          	beqz	a5,80006008 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f00:	100017b7          	lui	a5,0x10001
    80005f04:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f08:	43fc                	lw	a5,68(a5)
    80005f0a:	2781                	sext.w	a5,a5
    80005f0c:	10079663          	bnez	a5,80006018 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f10:	100017b7          	lui	a5,0x10001
    80005f14:	5bdc                	lw	a5,52(a5)
    80005f16:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f18:	10078863          	beqz	a5,80006028 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005f1c:	471d                	li	a4,7
    80005f1e:	10f77d63          	bgeu	a4,a5,80006038 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005f22:	ffffb097          	auipc	ra,0xffffb
    80005f26:	bd8080e7          	jalr	-1064(ra) # 80000afa <kalloc>
    80005f2a:	0001c497          	auipc	s1,0x1c
    80005f2e:	12648493          	addi	s1,s1,294 # 80022050 <disk>
    80005f32:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f34:	ffffb097          	auipc	ra,0xffffb
    80005f38:	bc6080e7          	jalr	-1082(ra) # 80000afa <kalloc>
    80005f3c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f3e:	ffffb097          	auipc	ra,0xffffb
    80005f42:	bbc080e7          	jalr	-1092(ra) # 80000afa <kalloc>
    80005f46:	87aa                	mv	a5,a0
    80005f48:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f4a:	6088                	ld	a0,0(s1)
    80005f4c:	cd75                	beqz	a0,80006048 <virtio_disk_init+0x1e0>
    80005f4e:	0001c717          	auipc	a4,0x1c
    80005f52:	10a73703          	ld	a4,266(a4) # 80022058 <disk+0x8>
    80005f56:	cb6d                	beqz	a4,80006048 <virtio_disk_init+0x1e0>
    80005f58:	cbe5                	beqz	a5,80006048 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005f5a:	6605                	lui	a2,0x1
    80005f5c:	4581                	li	a1,0
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	d88080e7          	jalr	-632(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f66:	0001c497          	auipc	s1,0x1c
    80005f6a:	0ea48493          	addi	s1,s1,234 # 80022050 <disk>
    80005f6e:	6605                	lui	a2,0x1
    80005f70:	4581                	li	a1,0
    80005f72:	6488                	ld	a0,8(s1)
    80005f74:	ffffb097          	auipc	ra,0xffffb
    80005f78:	d72080e7          	jalr	-654(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f7c:	6605                	lui	a2,0x1
    80005f7e:	4581                	li	a1,0
    80005f80:	6888                	ld	a0,16(s1)
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	d64080e7          	jalr	-668(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f8a:	100017b7          	lui	a5,0x10001
    80005f8e:	4721                	li	a4,8
    80005f90:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f92:	4098                	lw	a4,0(s1)
    80005f94:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f98:	40d8                	lw	a4,4(s1)
    80005f9a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f9e:	6498                	ld	a4,8(s1)
    80005fa0:	0007069b          	sext.w	a3,a4
    80005fa4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fa8:	9701                	srai	a4,a4,0x20
    80005faa:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fae:	6898                	ld	a4,16(s1)
    80005fb0:	0007069b          	sext.w	a3,a4
    80005fb4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fb8:	9701                	srai	a4,a4,0x20
    80005fba:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fbe:	4685                	li	a3,1
    80005fc0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005fc2:	4705                	li	a4,1
    80005fc4:	00d48c23          	sb	a3,24(s1)
    80005fc8:	00e48ca3          	sb	a4,25(s1)
    80005fcc:	00e48d23          	sb	a4,26(s1)
    80005fd0:	00e48da3          	sb	a4,27(s1)
    80005fd4:	00e48e23          	sb	a4,28(s1)
    80005fd8:	00e48ea3          	sb	a4,29(s1)
    80005fdc:	00e48f23          	sb	a4,30(s1)
    80005fe0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fe4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe8:	0727a823          	sw	s2,112(a5)
}
    80005fec:	60e2                	ld	ra,24(sp)
    80005fee:	6442                	ld	s0,16(sp)
    80005ff0:	64a2                	ld	s1,8(sp)
    80005ff2:	6902                	ld	s2,0(sp)
    80005ff4:	6105                	addi	sp,sp,32
    80005ff6:	8082                	ret
    panic("could not find virtio disk");
    80005ff8:	00002517          	auipc	a0,0x2
    80005ffc:	7a850513          	addi	a0,a0,1960 # 800087a0 <syscalls+0x330>
    80006000:	ffffa097          	auipc	ra,0xffffa
    80006004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006008:	00002517          	auipc	a0,0x2
    8000600c:	7b850513          	addi	a0,a0,1976 # 800087c0 <syscalls+0x350>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	534080e7          	jalr	1332(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006018:	00002517          	auipc	a0,0x2
    8000601c:	7c850513          	addi	a0,a0,1992 # 800087e0 <syscalls+0x370>
    80006020:	ffffa097          	auipc	ra,0xffffa
    80006024:	524080e7          	jalr	1316(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006028:	00002517          	auipc	a0,0x2
    8000602c:	7d850513          	addi	a0,a0,2008 # 80008800 <syscalls+0x390>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	514080e7          	jalr	1300(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006038:	00002517          	auipc	a0,0x2
    8000603c:	7e850513          	addi	a0,a0,2024 # 80008820 <syscalls+0x3b0>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	504080e7          	jalr	1284(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006048:	00002517          	auipc	a0,0x2
    8000604c:	7f850513          	addi	a0,a0,2040 # 80008840 <syscalls+0x3d0>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4f4080e7          	jalr	1268(ra) # 80000544 <panic>

0000000080006058 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006058:	7159                	addi	sp,sp,-112
    8000605a:	f486                	sd	ra,104(sp)
    8000605c:	f0a2                	sd	s0,96(sp)
    8000605e:	eca6                	sd	s1,88(sp)
    80006060:	e8ca                	sd	s2,80(sp)
    80006062:	e4ce                	sd	s3,72(sp)
    80006064:	e0d2                	sd	s4,64(sp)
    80006066:	fc56                	sd	s5,56(sp)
    80006068:	f85a                	sd	s6,48(sp)
    8000606a:	f45e                	sd	s7,40(sp)
    8000606c:	f062                	sd	s8,32(sp)
    8000606e:	ec66                	sd	s9,24(sp)
    80006070:	e86a                	sd	s10,16(sp)
    80006072:	1880                	addi	s0,sp,112
    80006074:	892a                	mv	s2,a0
    80006076:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006078:	00c52c83          	lw	s9,12(a0)
    8000607c:	001c9c9b          	slliw	s9,s9,0x1
    80006080:	1c82                	slli	s9,s9,0x20
    80006082:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006086:	0001c517          	auipc	a0,0x1c
    8000608a:	0f250513          	addi	a0,a0,242 # 80022178 <disk+0x128>
    8000608e:	ffffb097          	auipc	ra,0xffffb
    80006092:	b5c080e7          	jalr	-1188(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006096:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006098:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000609a:	0001cb17          	auipc	s6,0x1c
    8000609e:	fb6b0b13          	addi	s6,s6,-74 # 80022050 <disk>
  for(int i = 0; i < 3; i++){
    800060a2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060a4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060a6:	0001cc17          	auipc	s8,0x1c
    800060aa:	0d2c0c13          	addi	s8,s8,210 # 80022178 <disk+0x128>
    800060ae:	a8b5                	j	8000612a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800060b0:	00fb06b3          	add	a3,s6,a5
    800060b4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060b8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060ba:	0207c563          	bltz	a5,800060e4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060be:	2485                	addiw	s1,s1,1
    800060c0:	0711                	addi	a4,a4,4
    800060c2:	1f548a63          	beq	s1,s5,800062b6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800060c6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060c8:	0001c697          	auipc	a3,0x1c
    800060cc:	f8868693          	addi	a3,a3,-120 # 80022050 <disk>
    800060d0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060d2:	0186c583          	lbu	a1,24(a3)
    800060d6:	fde9                	bnez	a1,800060b0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060d8:	2785                	addiw	a5,a5,1
    800060da:	0685                	addi	a3,a3,1
    800060dc:	ff779be3          	bne	a5,s7,800060d2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060e0:	57fd                	li	a5,-1
    800060e2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060e4:	02905a63          	blez	s1,80006118 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060e8:	f9042503          	lw	a0,-112(s0)
    800060ec:	00000097          	auipc	ra,0x0
    800060f0:	cfa080e7          	jalr	-774(ra) # 80005de6 <free_desc>
      for(int j = 0; j < i; j++)
    800060f4:	4785                	li	a5,1
    800060f6:	0297d163          	bge	a5,s1,80006118 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060fa:	f9442503          	lw	a0,-108(s0)
    800060fe:	00000097          	auipc	ra,0x0
    80006102:	ce8080e7          	jalr	-792(ra) # 80005de6 <free_desc>
      for(int j = 0; j < i; j++)
    80006106:	4789                	li	a5,2
    80006108:	0097d863          	bge	a5,s1,80006118 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000610c:	f9842503          	lw	a0,-104(s0)
    80006110:	00000097          	auipc	ra,0x0
    80006114:	cd6080e7          	jalr	-810(ra) # 80005de6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006118:	85e2                	mv	a1,s8
    8000611a:	0001c517          	auipc	a0,0x1c
    8000611e:	f4e50513          	addi	a0,a0,-178 # 80022068 <disk+0x18>
    80006122:	ffffc097          	auipc	ra,0xffffc
    80006126:	fca080e7          	jalr	-54(ra) # 800020ec <sleep>
  for(int i = 0; i < 3; i++){
    8000612a:	f9040713          	addi	a4,s0,-112
    8000612e:	84ce                	mv	s1,s3
    80006130:	bf59                	j	800060c6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006132:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006136:	00479693          	slli	a3,a5,0x4
    8000613a:	0001c797          	auipc	a5,0x1c
    8000613e:	f1678793          	addi	a5,a5,-234 # 80022050 <disk>
    80006142:	97b6                	add	a5,a5,a3
    80006144:	4685                	li	a3,1
    80006146:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006148:	0001c597          	auipc	a1,0x1c
    8000614c:	f0858593          	addi	a1,a1,-248 # 80022050 <disk>
    80006150:	00a60793          	addi	a5,a2,10
    80006154:	0792                	slli	a5,a5,0x4
    80006156:	97ae                	add	a5,a5,a1
    80006158:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000615c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006160:	f6070693          	addi	a3,a4,-160
    80006164:	619c                	ld	a5,0(a1)
    80006166:	97b6                	add	a5,a5,a3
    80006168:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000616a:	6188                	ld	a0,0(a1)
    8000616c:	96aa                	add	a3,a3,a0
    8000616e:	47c1                	li	a5,16
    80006170:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006172:	4785                	li	a5,1
    80006174:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006178:	f9442783          	lw	a5,-108(s0)
    8000617c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006180:	0792                	slli	a5,a5,0x4
    80006182:	953e                	add	a0,a0,a5
    80006184:	05890693          	addi	a3,s2,88
    80006188:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000618a:	6188                	ld	a0,0(a1)
    8000618c:	97aa                	add	a5,a5,a0
    8000618e:	40000693          	li	a3,1024
    80006192:	c794                	sw	a3,8(a5)
  if(write)
    80006194:	100d0d63          	beqz	s10,800062ae <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006198:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000619c:	00c7d683          	lhu	a3,12(a5)
    800061a0:	0016e693          	ori	a3,a3,1
    800061a4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800061a8:	f9842583          	lw	a1,-104(s0)
    800061ac:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061b0:	0001c697          	auipc	a3,0x1c
    800061b4:	ea068693          	addi	a3,a3,-352 # 80022050 <disk>
    800061b8:	00260793          	addi	a5,a2,2
    800061bc:	0792                	slli	a5,a5,0x4
    800061be:	97b6                	add	a5,a5,a3
    800061c0:	587d                	li	a6,-1
    800061c2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061c6:	0592                	slli	a1,a1,0x4
    800061c8:	952e                	add	a0,a0,a1
    800061ca:	f9070713          	addi	a4,a4,-112
    800061ce:	9736                	add	a4,a4,a3
    800061d0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800061d2:	6298                	ld	a4,0(a3)
    800061d4:	972e                	add	a4,a4,a1
    800061d6:	4585                	li	a1,1
    800061d8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061da:	4509                	li	a0,2
    800061dc:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800061e0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061e4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061e8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061ec:	6698                	ld	a4,8(a3)
    800061ee:	00275783          	lhu	a5,2(a4)
    800061f2:	8b9d                	andi	a5,a5,7
    800061f4:	0786                	slli	a5,a5,0x1
    800061f6:	97ba                	add	a5,a5,a4
    800061f8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800061fc:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006200:	6698                	ld	a4,8(a3)
    80006202:	00275783          	lhu	a5,2(a4)
    80006206:	2785                	addiw	a5,a5,1
    80006208:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000620c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006210:	100017b7          	lui	a5,0x10001
    80006214:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006218:	00492703          	lw	a4,4(s2)
    8000621c:	4785                	li	a5,1
    8000621e:	02f71163          	bne	a4,a5,80006240 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006222:	0001c997          	auipc	s3,0x1c
    80006226:	f5698993          	addi	s3,s3,-170 # 80022178 <disk+0x128>
  while(b->disk == 1) {
    8000622a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000622c:	85ce                	mv	a1,s3
    8000622e:	854a                	mv	a0,s2
    80006230:	ffffc097          	auipc	ra,0xffffc
    80006234:	ebc080e7          	jalr	-324(ra) # 800020ec <sleep>
  while(b->disk == 1) {
    80006238:	00492783          	lw	a5,4(s2)
    8000623c:	fe9788e3          	beq	a5,s1,8000622c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006240:	f9042903          	lw	s2,-112(s0)
    80006244:	00290793          	addi	a5,s2,2
    80006248:	00479713          	slli	a4,a5,0x4
    8000624c:	0001c797          	auipc	a5,0x1c
    80006250:	e0478793          	addi	a5,a5,-508 # 80022050 <disk>
    80006254:	97ba                	add	a5,a5,a4
    80006256:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000625a:	0001c997          	auipc	s3,0x1c
    8000625e:	df698993          	addi	s3,s3,-522 # 80022050 <disk>
    80006262:	00491713          	slli	a4,s2,0x4
    80006266:	0009b783          	ld	a5,0(s3)
    8000626a:	97ba                	add	a5,a5,a4
    8000626c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006270:	854a                	mv	a0,s2
    80006272:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006276:	00000097          	auipc	ra,0x0
    8000627a:	b70080e7          	jalr	-1168(ra) # 80005de6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000627e:	8885                	andi	s1,s1,1
    80006280:	f0ed                	bnez	s1,80006262 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006282:	0001c517          	auipc	a0,0x1c
    80006286:	ef650513          	addi	a0,a0,-266 # 80022178 <disk+0x128>
    8000628a:	ffffb097          	auipc	ra,0xffffb
    8000628e:	a14080e7          	jalr	-1516(ra) # 80000c9e <release>
}
    80006292:	70a6                	ld	ra,104(sp)
    80006294:	7406                	ld	s0,96(sp)
    80006296:	64e6                	ld	s1,88(sp)
    80006298:	6946                	ld	s2,80(sp)
    8000629a:	69a6                	ld	s3,72(sp)
    8000629c:	6a06                	ld	s4,64(sp)
    8000629e:	7ae2                	ld	s5,56(sp)
    800062a0:	7b42                	ld	s6,48(sp)
    800062a2:	7ba2                	ld	s7,40(sp)
    800062a4:	7c02                	ld	s8,32(sp)
    800062a6:	6ce2                	ld	s9,24(sp)
    800062a8:	6d42                	ld	s10,16(sp)
    800062aa:	6165                	addi	sp,sp,112
    800062ac:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062ae:	4689                	li	a3,2
    800062b0:	00d79623          	sh	a3,12(a5)
    800062b4:	b5e5                	j	8000619c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062b6:	f9042603          	lw	a2,-112(s0)
    800062ba:	00a60713          	addi	a4,a2,10
    800062be:	0712                	slli	a4,a4,0x4
    800062c0:	0001c517          	auipc	a0,0x1c
    800062c4:	d9850513          	addi	a0,a0,-616 # 80022058 <disk+0x8>
    800062c8:	953a                	add	a0,a0,a4
  if(write)
    800062ca:	e60d14e3          	bnez	s10,80006132 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062ce:	00a60793          	addi	a5,a2,10
    800062d2:	00479693          	slli	a3,a5,0x4
    800062d6:	0001c797          	auipc	a5,0x1c
    800062da:	d7a78793          	addi	a5,a5,-646 # 80022050 <disk>
    800062de:	97b6                	add	a5,a5,a3
    800062e0:	0007a423          	sw	zero,8(a5)
    800062e4:	b595                	j	80006148 <virtio_disk_rw+0xf0>

00000000800062e6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062e6:	1101                	addi	sp,sp,-32
    800062e8:	ec06                	sd	ra,24(sp)
    800062ea:	e822                	sd	s0,16(sp)
    800062ec:	e426                	sd	s1,8(sp)
    800062ee:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062f0:	0001c497          	auipc	s1,0x1c
    800062f4:	d6048493          	addi	s1,s1,-672 # 80022050 <disk>
    800062f8:	0001c517          	auipc	a0,0x1c
    800062fc:	e8050513          	addi	a0,a0,-384 # 80022178 <disk+0x128>
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	8ea080e7          	jalr	-1814(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006308:	10001737          	lui	a4,0x10001
    8000630c:	533c                	lw	a5,96(a4)
    8000630e:	8b8d                	andi	a5,a5,3
    80006310:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006312:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006316:	689c                	ld	a5,16(s1)
    80006318:	0204d703          	lhu	a4,32(s1)
    8000631c:	0027d783          	lhu	a5,2(a5)
    80006320:	04f70863          	beq	a4,a5,80006370 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006324:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006328:	6898                	ld	a4,16(s1)
    8000632a:	0204d783          	lhu	a5,32(s1)
    8000632e:	8b9d                	andi	a5,a5,7
    80006330:	078e                	slli	a5,a5,0x3
    80006332:	97ba                	add	a5,a5,a4
    80006334:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006336:	00278713          	addi	a4,a5,2
    8000633a:	0712                	slli	a4,a4,0x4
    8000633c:	9726                	add	a4,a4,s1
    8000633e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006342:	e721                	bnez	a4,8000638a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006344:	0789                	addi	a5,a5,2
    80006346:	0792                	slli	a5,a5,0x4
    80006348:	97a6                	add	a5,a5,s1
    8000634a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000634c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006350:	ffffc097          	auipc	ra,0xffffc
    80006354:	e00080e7          	jalr	-512(ra) # 80002150 <wakeup>

    disk.used_idx += 1;
    80006358:	0204d783          	lhu	a5,32(s1)
    8000635c:	2785                	addiw	a5,a5,1
    8000635e:	17c2                	slli	a5,a5,0x30
    80006360:	93c1                	srli	a5,a5,0x30
    80006362:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006366:	6898                	ld	a4,16(s1)
    80006368:	00275703          	lhu	a4,2(a4)
    8000636c:	faf71ce3          	bne	a4,a5,80006324 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006370:	0001c517          	auipc	a0,0x1c
    80006374:	e0850513          	addi	a0,a0,-504 # 80022178 <disk+0x128>
    80006378:	ffffb097          	auipc	ra,0xffffb
    8000637c:	926080e7          	jalr	-1754(ra) # 80000c9e <release>
}
    80006380:	60e2                	ld	ra,24(sp)
    80006382:	6442                	ld	s0,16(sp)
    80006384:	64a2                	ld	s1,8(sp)
    80006386:	6105                	addi	sp,sp,32
    80006388:	8082                	ret
      panic("virtio_disk_intr status");
    8000638a:	00002517          	auipc	a0,0x2
    8000638e:	4ce50513          	addi	a0,a0,1230 # 80008858 <syscalls+0x3e8>
    80006392:	ffffa097          	auipc	ra,0xffffa
    80006396:	1b2080e7          	jalr	434(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
