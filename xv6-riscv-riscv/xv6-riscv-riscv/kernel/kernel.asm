
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	90013103          	ld	sp,-1792(sp) # 80008900 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	90e70713          	addi	a4,a4,-1778 # 80008960 <timer_scratch>
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
    80000068:	ccc78793          	addi	a5,a5,-820 # 80005d30 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc62f>
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
    80000130:	414080e7          	jalr	1044(ra) # 80002540 <either_copyin>
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
    80000190:	91450513          	addi	a0,a0,-1772 # 80010aa0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	90448493          	addi	s1,s1,-1788 # 80010aa0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	99290913          	addi	s2,s2,-1646 # 80010b38 <cons+0x98>
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
    800001d0:	1be080e7          	jalr	446(ra) # 8000238a <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	f08080e7          	jalr	-248(ra) # 800020e2 <sleep>
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
    8000021a:	2d4080e7          	jalr	724(ra) # 800024ea <either_copyout>
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
    8000022e:	87650513          	addi	a0,a0,-1930 # 80010aa0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	86050513          	addi	a0,a0,-1952 # 80010aa0 <cons>
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
    8000027c:	8cf72023          	sw	a5,-1856(a4) # 80010b38 <cons+0x98>
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
    800002d6:	7ce50513          	addi	a0,a0,1998 # 80010aa0 <cons>
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
    800002fc:	29e080e7          	jalr	670(ra) # 80002596 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	7a050513          	addi	a0,a0,1952 # 80010aa0 <cons>
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
    80000328:	77c70713          	addi	a4,a4,1916 # 80010aa0 <cons>
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
    80000352:	75278793          	addi	a5,a5,1874 # 80010aa0 <cons>
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
    80000380:	7bc7a783          	lw	a5,1980(a5) # 80010b38 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	71070713          	addi	a4,a4,1808 # 80010aa0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	70048493          	addi	s1,s1,1792 # 80010aa0 <cons>
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
    800003e0:	6c470713          	addi	a4,a4,1732 # 80010aa0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	74f72723          	sw	a5,1870(a4) # 80010b40 <cons+0xa0>
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
    8000041c:	68878793          	addi	a5,a5,1672 # 80010aa0 <cons>
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
    80000440:	70c7a023          	sw	a2,1792(a5) # 80010b3c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	6f450513          	addi	a0,a0,1780 # 80010b38 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	cfa080e7          	jalr	-774(ra) # 80002146 <wakeup>
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
    8000046a:	63a50513          	addi	a0,a0,1594 # 80010aa0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	bba78793          	addi	a5,a5,-1094 # 80021038 <devsw>
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
    80000554:	6007a823          	sw	zero,1552(a5) # 80010b60 <pr+0x18>
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
    80000588:	38f72e23          	sw	a5,924(a4) # 80008920 <panicked>
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
    800005c4:	5a0dad83          	lw	s11,1440(s11) # 80010b60 <pr+0x18>
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
    80000602:	54a50513          	addi	a0,a0,1354 # 80010b48 <pr>
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
    80000766:	3e650513          	addi	a0,a0,998 # 80010b48 <pr>
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
    80000782:	3ca48493          	addi	s1,s1,970 # 80010b48 <pr>
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
    800007e2:	38a50513          	addi	a0,a0,906 # 80010b68 <uart_tx_lock>
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
    8000080e:	1167a783          	lw	a5,278(a5) # 80008920 <panicked>
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
    8000084a:	0e273703          	ld	a4,226(a4) # 80008928 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0e27b783          	ld	a5,226(a5) # 80008930 <uart_tx_w>
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
    80000874:	2f8a0a13          	addi	s4,s4,760 # 80010b68 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	0b048493          	addi	s1,s1,176 # 80008928 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	0b098993          	addi	s3,s3,176 # 80008930 <uart_tx_w>
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
    800008aa:	8a0080e7          	jalr	-1888(ra) # 80002146 <wakeup>
    
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
    800008e6:	28650513          	addi	a0,a0,646 # 80010b68 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	02e7a783          	lw	a5,46(a5) # 80008920 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	0347b783          	ld	a5,52(a5) # 80008930 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	02473703          	ld	a4,36(a4) # 80008928 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	258a0a13          	addi	s4,s4,600 # 80010b68 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	01048493          	addi	s1,s1,16 # 80008928 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	01090913          	addi	s2,s2,16 # 80008930 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	7b2080e7          	jalr	1970(ra) # 800020e2 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	22248493          	addi	s1,s1,546 # 80010b68 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	fcf73b23          	sd	a5,-42(a4) # 80008930 <uart_tx_w>
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
    800009d4:	19848493          	addi	s1,s1,408 # 80010b68 <uart_tx_lock>
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
    80000a16:	7be78793          	addi	a5,a5,1982 # 800221d0 <end>
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
    80000a36:	16e90913          	addi	s2,s2,366 # 80010ba0 <kmem>
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
    80000ad2:	0d250513          	addi	a0,a0,210 # 80010ba0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	6ee50513          	addi	a0,a0,1774 # 800221d0 <end>
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
    80000b08:	09c48493          	addi	s1,s1,156 # 80010ba0 <kmem>
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
    80000b20:	08450513          	addi	a0,a0,132 # 80010ba0 <kmem>
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
    80000b4c:	05850513          	addi	a0,a0,88 # 80010ba0 <kmem>
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
    80000ea8:	a9470713          	addi	a4,a4,-1388 # 80008938 <started>
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
    80000ede:	8ac080e7          	jalr	-1876(ra) # 80002786 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	e8e080e7          	jalr	-370(ra) # 80005d70 <plicinithart>
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
    80000f56:	80c080e7          	jalr	-2036(ra) # 8000275e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	82c080e7          	jalr	-2004(ra) # 80002786 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	df8080e7          	jalr	-520(ra) # 80005d5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	e06080e7          	jalr	-506(ra) # 80005d70 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	fb4080e7          	jalr	-76(ra) # 80002f26 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	658080e7          	jalr	1624(ra) # 800035d2 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	5f6080e7          	jalr	1526(ra) # 80004578 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	eee080e7          	jalr	-274(ra) # 80005e78 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d20080e7          	jalr	-736(ra) # 80001cb2 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	98f72c23          	sw	a5,-1640(a4) # 80008938 <started>
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
    80000fb8:	98c7b783          	ld	a5,-1652(a5) # 80008940 <kernel_pagetable>
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
    80001274:	6ca7b823          	sd	a0,1744(a5) # 80008940 <kernel_pagetable>
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
    8000186a:	78a48493          	addi	s1,s1,1930 # 80010ff0 <proc>
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
    80001884:	570a0a13          	addi	s4,s4,1392 # 80016df0 <tickslock>
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
    80001906:	2be50513          	addi	a0,a0,702 # 80010bc0 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	2be50513          	addi	a0,a0,702 # 80010bd8 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	0000f497          	auipc	s1,0xf
    8000192e:	6c648493          	addi	s1,s1,1734 # 80010ff0 <proc>
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
    80001950:	4a498993          	addi	s3,s3,1188 # 80016df0 <tickslock>
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
    800019ba:	23a50513          	addi	a0,a0,570 # 80010bf0 <cpus>
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
    800019e2:	1e270713          	addi	a4,a4,482 # 80010bc0 <pid_lock>
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
    80001a1a:	e9a7a783          	lw	a5,-358(a5) # 800088b0 <first.1689>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	d7e080e7          	jalr	-642(ra) # 8000279e <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e807a023          	sw	zero,-384(a5) # 800088b0 <first.1689>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	b18080e7          	jalr	-1256(ra) # 80003552 <fsinit>
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
    80001a54:	17090913          	addi	s2,s2,368 # 80010bc0 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	e5278793          	addi	a5,a5,-430 # 800088b4 <nextpid>
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
    80001be0:	41448493          	addi	s1,s1,1044 # 80010ff0 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	20c90913          	addi	s2,s2,524 # 80016df0 <tickslock>
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
  p->stride = BIG_NUM / p->tickets;
    80001c2e:	47a9                	li	a5,10
    80001c30:	dcdc                	sw	a5,60(s1)
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
    80001cca:	c8a7b123          	sd	a0,-894(a5) # 80008948 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cce:	03400613          	li	a2,52
    80001cd2:	00007597          	auipc	a1,0x7
    80001cd6:	bee58593          	addi	a1,a1,-1042 # 800088c0 <initcode>
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
    80001d14:	264080e7          	jalr	612(ra) # 80003f74 <namei>
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
    80001e32:	7dc080e7          	jalr	2012(ra) # 8000460a <filedup>
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
    80001e54:	940080e7          	jalr	-1728(ra) # 80003790 <idup>
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
    80001e80:	d5c48493          	addi	s1,s1,-676 # 80010bd8 <wait_lock>
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
    80001ef0:	cd470713          	addi	a4,a4,-812 # 80010bc0 <pid_lock>
    80001ef4:	9736                	add	a4,a4,a3
    80001ef6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &lowest_pass_p->context);
    80001efa:	0000f717          	auipc	a4,0xf
    80001efe:	cfe70713          	addi	a4,a4,-770 # 80010bf8 <cpus+0x8>
    80001f02:	00e68c33          	add	s8,a3,a4
      if (p->state == RUNNABLE) {
    80001f06:	4a0d                	li	s4,3
    for(p=proc; p < &proc[NPROC]; p++){
    80001f08:	00015a97          	auipc	s5,0x15
    80001f0c:	ee8a8a93          	addi	s5,s5,-280 # 80016df0 <tickslock>
    struct proc *lowest_pass_p = 0;
    80001f10:	4b01                	li	s6,0
        c->proc = lowest_pass_p;
    80001f12:	0000fb97          	auipc	s7,0xf
    80001f16:	caeb8b93          	addi	s7,s7,-850 # 80010bc0 <pid_lock>
    80001f1a:	9bb6                	add	s7,s7,a3
    80001f1c:	a0b5                	j	80001f88 <scheduler+0xbc>
        release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	d7e080e7          	jalr	-642(ra) # 80000c9e <release>
    for(p=proc; p < &proc[NPROC]; p++){
    80001f28:	17848793          	addi	a5,s1,376
    80001f2c:	0557f563          	bgeu	a5,s5,80001f76 <scheduler+0xaa>
    80001f30:	17848493          	addi	s1,s1,376
      acquire(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	cb4080e7          	jalr	-844(ra) # 80000bea <acquire>
      if (p->state == RUNNABLE) {
    80001f3e:	4c9c                	lw	a5,24(s1)
    80001f40:	03479063          	bne	a5,s4,80001f60 <scheduler+0x94>
      if (lowest_pass_p == 0 || lowest_pass_p->pass > p->pass) {
    80001f44:	08098463          	beqz	s3,80001fcc <scheduler+0x100>
    80001f48:	0409a703          	lw	a4,64(s3)
    80001f4c:	40bc                	lw	a5,64(s1)
    80001f4e:	fce7d8e3          	bge	a5,a4,80001f1e <scheduler+0x52>
          release(&lowest_pass_p->lock);
    80001f52:	854e                	mv	a0,s3
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d4a080e7          	jalr	-694(ra) # 80000c9e <release>
    80001f5c:	89a6                	mv	s3,s1
    80001f5e:	b7e9                	j	80001f28 <scheduler+0x5c>
        release(&p->lock);
    80001f60:	8526                	mv	a0,s1
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	d3c080e7          	jalr	-708(ra) # 80000c9e <release>
    for(p=proc; p < &proc[NPROC]; p++){
    80001f6a:	17848793          	addi	a5,s1,376
    80001f6e:	fd57e1e3          	bltu	a5,s5,80001f30 <scheduler+0x64>
    if(lowest_pass_p == 0) {
    80001f72:	00098b63          	beqz	s3,80001f88 <scheduler+0xbc>
      if(lowest_pass_p->state == RUNNABLE) {
    80001f76:	0189a783          	lw	a5,24(s3)
    80001f7a:	03478363          	beq	a5,s4,80001fa0 <scheduler+0xd4>
      release(&lowest_pass_p->lock);
    80001f7e:	854e                	mv	a0,s3
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	d1e080e7          	jalr	-738(ra) # 80000c9e <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f8c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f90:	10079073          	csrw	sstatus,a5
    for(p=proc; p < &proc[NPROC]; p++){
    80001f94:	0000f497          	auipc	s1,0xf
    80001f98:	05c48493          	addi	s1,s1,92 # 80010ff0 <proc>
    struct proc *lowest_pass_p = 0;
    80001f9c:	89da                	mv	s3,s6
    80001f9e:	bf59                	j	80001f34 <scheduler+0x68>
        lowest_pass_p->state = RUNNING;
    80001fa0:	4791                	li	a5,4
    80001fa2:	00f9ac23          	sw	a5,24(s3)
        c->proc = lowest_pass_p;
    80001fa6:	033bb823          	sd	s3,48(s7)
        lowest_pass_p->pass += lowest_pass_p->stride;
    80001faa:	0409a783          	lw	a5,64(s3)
    80001fae:	03c9a703          	lw	a4,60(s3)
    80001fb2:	9fb9                	addw	a5,a5,a4
    80001fb4:	04f9a023          	sw	a5,64(s3)
        swtch(&c->context, &lowest_pass_p->context);
    80001fb8:	07098593          	addi	a1,s3,112
    80001fbc:	8562                	mv	a0,s8
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	736080e7          	jalr	1846(ra) # 800026f4 <swtch>
        c->proc = 0;
    80001fc6:	020bb823          	sd	zero,48(s7)
    80001fca:	bf55                	j	80001f7e <scheduler+0xb2>
    80001fcc:	89a6                	mv	s3,s1
    80001fce:	bfa9                	j	80001f28 <scheduler+0x5c>

0000000080001fd0 <sched>:
{
    80001fd0:	7179                	addi	sp,sp,-48
    80001fd2:	f406                	sd	ra,40(sp)
    80001fd4:	f022                	sd	s0,32(sp)
    80001fd6:	ec26                	sd	s1,24(sp)
    80001fd8:	e84a                	sd	s2,16(sp)
    80001fda:	e44e                	sd	s3,8(sp)
    80001fdc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fde:	00000097          	auipc	ra,0x0
    80001fe2:	9e8080e7          	jalr	-1560(ra) # 800019c6 <myproc>
    80001fe6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	b88080e7          	jalr	-1144(ra) # 80000b70 <holding>
    80001ff0:	c93d                	beqz	a0,80002066 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ff4:	2781                	sext.w	a5,a5
    80001ff6:	079e                	slli	a5,a5,0x7
    80001ff8:	0000f717          	auipc	a4,0xf
    80001ffc:	bc870713          	addi	a4,a4,-1080 # 80010bc0 <pid_lock>
    80002000:	97ba                	add	a5,a5,a4
    80002002:	0a87a703          	lw	a4,168(a5)
    80002006:	4785                	li	a5,1
    80002008:	06f71763          	bne	a4,a5,80002076 <sched+0xa6>
  if(p->state == RUNNING)
    8000200c:	4c98                	lw	a4,24(s1)
    8000200e:	4791                	li	a5,4
    80002010:	06f70b63          	beq	a4,a5,80002086 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002014:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002018:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000201a:	efb5                	bnez	a5,80002096 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000201c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000201e:	0000f917          	auipc	s2,0xf
    80002022:	ba290913          	addi	s2,s2,-1118 # 80010bc0 <pid_lock>
    80002026:	2781                	sext.w	a5,a5
    80002028:	079e                	slli	a5,a5,0x7
    8000202a:	97ca                	add	a5,a5,s2
    8000202c:	0ac7a983          	lw	s3,172(a5)
    80002030:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002032:	2781                	sext.w	a5,a5
    80002034:	079e                	slli	a5,a5,0x7
    80002036:	0000f597          	auipc	a1,0xf
    8000203a:	bc258593          	addi	a1,a1,-1086 # 80010bf8 <cpus+0x8>
    8000203e:	95be                	add	a1,a1,a5
    80002040:	07048513          	addi	a0,s1,112
    80002044:	00000097          	auipc	ra,0x0
    80002048:	6b0080e7          	jalr	1712(ra) # 800026f4 <swtch>
    8000204c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000204e:	2781                	sext.w	a5,a5
    80002050:	079e                	slli	a5,a5,0x7
    80002052:	97ca                	add	a5,a5,s2
    80002054:	0b37a623          	sw	s3,172(a5)
}
    80002058:	70a2                	ld	ra,40(sp)
    8000205a:	7402                	ld	s0,32(sp)
    8000205c:	64e2                	ld	s1,24(sp)
    8000205e:	6942                	ld	s2,16(sp)
    80002060:	69a2                	ld	s3,8(sp)
    80002062:	6145                	addi	sp,sp,48
    80002064:	8082                	ret
    panic("sched p->lock");
    80002066:	00006517          	auipc	a0,0x6
    8000206a:	1b250513          	addi	a0,a0,434 # 80008218 <digits+0x1d8>
    8000206e:	ffffe097          	auipc	ra,0xffffe
    80002072:	4d6080e7          	jalr	1238(ra) # 80000544 <panic>
    panic("sched locks");
    80002076:	00006517          	auipc	a0,0x6
    8000207a:	1b250513          	addi	a0,a0,434 # 80008228 <digits+0x1e8>
    8000207e:	ffffe097          	auipc	ra,0xffffe
    80002082:	4c6080e7          	jalr	1222(ra) # 80000544 <panic>
    panic("sched running");
    80002086:	00006517          	auipc	a0,0x6
    8000208a:	1b250513          	addi	a0,a0,434 # 80008238 <digits+0x1f8>
    8000208e:	ffffe097          	auipc	ra,0xffffe
    80002092:	4b6080e7          	jalr	1206(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002096:	00006517          	auipc	a0,0x6
    8000209a:	1b250513          	addi	a0,a0,434 # 80008248 <digits+0x208>
    8000209e:	ffffe097          	auipc	ra,0xffffe
    800020a2:	4a6080e7          	jalr	1190(ra) # 80000544 <panic>

00000000800020a6 <yield>:
{
    800020a6:	1101                	addi	sp,sp,-32
    800020a8:	ec06                	sd	ra,24(sp)
    800020aa:	e822                	sd	s0,16(sp)
    800020ac:	e426                	sd	s1,8(sp)
    800020ae:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020b0:	00000097          	auipc	ra,0x0
    800020b4:	916080e7          	jalr	-1770(ra) # 800019c6 <myproc>
    800020b8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	b30080e7          	jalr	-1232(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800020c2:	478d                	li	a5,3
    800020c4:	cc9c                	sw	a5,24(s1)
  sched();
    800020c6:	00000097          	auipc	ra,0x0
    800020ca:	f0a080e7          	jalr	-246(ra) # 80001fd0 <sched>
  release(&p->lock);
    800020ce:	8526                	mv	a0,s1
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	bce080e7          	jalr	-1074(ra) # 80000c9e <release>
}
    800020d8:	60e2                	ld	ra,24(sp)
    800020da:	6442                	ld	s0,16(sp)
    800020dc:	64a2                	ld	s1,8(sp)
    800020de:	6105                	addi	sp,sp,32
    800020e0:	8082                	ret

00000000800020e2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020e2:	7179                	addi	sp,sp,-48
    800020e4:	f406                	sd	ra,40(sp)
    800020e6:	f022                	sd	s0,32(sp)
    800020e8:	ec26                	sd	s1,24(sp)
    800020ea:	e84a                	sd	s2,16(sp)
    800020ec:	e44e                	sd	s3,8(sp)
    800020ee:	1800                	addi	s0,sp,48
    800020f0:	89aa                	mv	s3,a0
    800020f2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8d2080e7          	jalr	-1838(ra) # 800019c6 <myproc>
    800020fc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	aec080e7          	jalr	-1300(ra) # 80000bea <acquire>
  release(lk);
    80002106:	854a                	mv	a0,s2
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	b96080e7          	jalr	-1130(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002110:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002114:	4789                	li	a5,2
    80002116:	cc9c                	sw	a5,24(s1)

  sched();
    80002118:	00000097          	auipc	ra,0x0
    8000211c:	eb8080e7          	jalr	-328(ra) # 80001fd0 <sched>

  // Tidy up.
  p->chan = 0;
    80002120:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002124:	8526                	mv	a0,s1
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	b78080e7          	jalr	-1160(ra) # 80000c9e <release>
  acquire(lk);
    8000212e:	854a                	mv	a0,s2
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	aba080e7          	jalr	-1350(ra) # 80000bea <acquire>
}
    80002138:	70a2                	ld	ra,40(sp)
    8000213a:	7402                	ld	s0,32(sp)
    8000213c:	64e2                	ld	s1,24(sp)
    8000213e:	6942                	ld	s2,16(sp)
    80002140:	69a2                	ld	s3,8(sp)
    80002142:	6145                	addi	sp,sp,48
    80002144:	8082                	ret

0000000080002146 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002146:	7139                	addi	sp,sp,-64
    80002148:	fc06                	sd	ra,56(sp)
    8000214a:	f822                	sd	s0,48(sp)
    8000214c:	f426                	sd	s1,40(sp)
    8000214e:	f04a                	sd	s2,32(sp)
    80002150:	ec4e                	sd	s3,24(sp)
    80002152:	e852                	sd	s4,16(sp)
    80002154:	e456                	sd	s5,8(sp)
    80002156:	0080                	addi	s0,sp,64
    80002158:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000215a:	0000f497          	auipc	s1,0xf
    8000215e:	e9648493          	addi	s1,s1,-362 # 80010ff0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002162:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002164:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002166:	00015917          	auipc	s2,0x15
    8000216a:	c8a90913          	addi	s2,s2,-886 # 80016df0 <tickslock>
    8000216e:	a821                	j	80002186 <wakeup+0x40>
        p->state = RUNNABLE;
    80002170:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b28080e7          	jalr	-1240(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	17848493          	addi	s1,s1,376
    80002182:	03248463          	beq	s1,s2,800021aa <wakeup+0x64>
    if(p != myproc()){
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	840080e7          	jalr	-1984(ra) # 800019c6 <myproc>
    8000218e:	fea488e3          	beq	s1,a0,8000217e <wakeup+0x38>
      acquire(&p->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000219c:	4c9c                	lw	a5,24(s1)
    8000219e:	fd379be3          	bne	a5,s3,80002174 <wakeup+0x2e>
    800021a2:	709c                	ld	a5,32(s1)
    800021a4:	fd4798e3          	bne	a5,s4,80002174 <wakeup+0x2e>
    800021a8:	b7e1                	j	80002170 <wakeup+0x2a>
    }
  }
}
    800021aa:	70e2                	ld	ra,56(sp)
    800021ac:	7442                	ld	s0,48(sp)
    800021ae:	74a2                	ld	s1,40(sp)
    800021b0:	7902                	ld	s2,32(sp)
    800021b2:	69e2                	ld	s3,24(sp)
    800021b4:	6a42                	ld	s4,16(sp)
    800021b6:	6aa2                	ld	s5,8(sp)
    800021b8:	6121                	addi	sp,sp,64
    800021ba:	8082                	ret

00000000800021bc <reparent>:
{
    800021bc:	7179                	addi	sp,sp,-48
    800021be:	f406                	sd	ra,40(sp)
    800021c0:	f022                	sd	s0,32(sp)
    800021c2:	ec26                	sd	s1,24(sp)
    800021c4:	e84a                	sd	s2,16(sp)
    800021c6:	e44e                	sd	s3,8(sp)
    800021c8:	e052                	sd	s4,0(sp)
    800021ca:	1800                	addi	s0,sp,48
    800021cc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021ce:	0000f497          	auipc	s1,0xf
    800021d2:	e2248493          	addi	s1,s1,-478 # 80010ff0 <proc>
      pp->parent = initproc;
    800021d6:	00006a17          	auipc	s4,0x6
    800021da:	772a0a13          	addi	s4,s4,1906 # 80008948 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021de:	00015997          	auipc	s3,0x15
    800021e2:	c1298993          	addi	s3,s3,-1006 # 80016df0 <tickslock>
    800021e6:	a029                	j	800021f0 <reparent+0x34>
    800021e8:	17848493          	addi	s1,s1,376
    800021ec:	01348d63          	beq	s1,s3,80002206 <reparent+0x4a>
    if(pp->parent == p){
    800021f0:	64bc                	ld	a5,72(s1)
    800021f2:	ff279be3          	bne	a5,s2,800021e8 <reparent+0x2c>
      pp->parent = initproc;
    800021f6:	000a3503          	ld	a0,0(s4)
    800021fa:	e4a8                	sd	a0,72(s1)
      wakeup(initproc);
    800021fc:	00000097          	auipc	ra,0x0
    80002200:	f4a080e7          	jalr	-182(ra) # 80002146 <wakeup>
    80002204:	b7d5                	j	800021e8 <reparent+0x2c>
}
    80002206:	70a2                	ld	ra,40(sp)
    80002208:	7402                	ld	s0,32(sp)
    8000220a:	64e2                	ld	s1,24(sp)
    8000220c:	6942                	ld	s2,16(sp)
    8000220e:	69a2                	ld	s3,8(sp)
    80002210:	6a02                	ld	s4,0(sp)
    80002212:	6145                	addi	sp,sp,48
    80002214:	8082                	ret

0000000080002216 <exit>:
{
    80002216:	7179                	addi	sp,sp,-48
    80002218:	f406                	sd	ra,40(sp)
    8000221a:	f022                	sd	s0,32(sp)
    8000221c:	ec26                	sd	s1,24(sp)
    8000221e:	e84a                	sd	s2,16(sp)
    80002220:	e44e                	sd	s3,8(sp)
    80002222:	e052                	sd	s4,0(sp)
    80002224:	1800                	addi	s0,sp,48
    80002226:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	79e080e7          	jalr	1950(ra) # 800019c6 <myproc>
    80002230:	89aa                	mv	s3,a0
  if(p == initproc)
    80002232:	00006797          	auipc	a5,0x6
    80002236:	7167b783          	ld	a5,1814(a5) # 80008948 <initproc>
    8000223a:	0e050493          	addi	s1,a0,224
    8000223e:	16050913          	addi	s2,a0,352
    80002242:	02a79363          	bne	a5,a0,80002268 <exit+0x52>
    panic("init exiting");
    80002246:	00006517          	auipc	a0,0x6
    8000224a:	01a50513          	addi	a0,a0,26 # 80008260 <digits+0x220>
    8000224e:	ffffe097          	auipc	ra,0xffffe
    80002252:	2f6080e7          	jalr	758(ra) # 80000544 <panic>
      fileclose(f);
    80002256:	00002097          	auipc	ra,0x2
    8000225a:	406080e7          	jalr	1030(ra) # 8000465c <fileclose>
      p->ofile[fd] = 0;
    8000225e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002262:	04a1                	addi	s1,s1,8
    80002264:	01248563          	beq	s1,s2,8000226e <exit+0x58>
    if(p->ofile[fd]){
    80002268:	6088                	ld	a0,0(s1)
    8000226a:	f575                	bnez	a0,80002256 <exit+0x40>
    8000226c:	bfdd                	j	80002262 <exit+0x4c>
  begin_op();
    8000226e:	00002097          	auipc	ra,0x2
    80002272:	f22080e7          	jalr	-222(ra) # 80004190 <begin_op>
  iput(p->cwd);
    80002276:	1609b503          	ld	a0,352(s3)
    8000227a:	00001097          	auipc	ra,0x1
    8000227e:	70e080e7          	jalr	1806(ra) # 80003988 <iput>
  end_op();
    80002282:	00002097          	auipc	ra,0x2
    80002286:	f8e080e7          	jalr	-114(ra) # 80004210 <end_op>
  p->cwd = 0;
    8000228a:	1609b023          	sd	zero,352(s3)
  acquire(&wait_lock);
    8000228e:	0000f497          	auipc	s1,0xf
    80002292:	94a48493          	addi	s1,s1,-1718 # 80010bd8 <wait_lock>
    80002296:	8526                	mv	a0,s1
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	952080e7          	jalr	-1710(ra) # 80000bea <acquire>
  reparent(p);
    800022a0:	854e                	mv	a0,s3
    800022a2:	00000097          	auipc	ra,0x0
    800022a6:	f1a080e7          	jalr	-230(ra) # 800021bc <reparent>
  wakeup(p->parent);
    800022aa:	0489b503          	ld	a0,72(s3)
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	e98080e7          	jalr	-360(ra) # 80002146 <wakeup>
  acquire(&p->lock);
    800022b6:	854e                	mv	a0,s3
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	932080e7          	jalr	-1742(ra) # 80000bea <acquire>
  p->xstate = status;
    800022c0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022c4:	4795                	li	a5,5
    800022c6:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	9d2080e7          	jalr	-1582(ra) # 80000c9e <release>
  sched();
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	cfc080e7          	jalr	-772(ra) # 80001fd0 <sched>
  panic("zombie exit");
    800022dc:	00006517          	auipc	a0,0x6
    800022e0:	f9450513          	addi	a0,a0,-108 # 80008270 <digits+0x230>
    800022e4:	ffffe097          	auipc	ra,0xffffe
    800022e8:	260080e7          	jalr	608(ra) # 80000544 <panic>

00000000800022ec <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022ec:	7179                	addi	sp,sp,-48
    800022ee:	f406                	sd	ra,40(sp)
    800022f0:	f022                	sd	s0,32(sp)
    800022f2:	ec26                	sd	s1,24(sp)
    800022f4:	e84a                	sd	s2,16(sp)
    800022f6:	e44e                	sd	s3,8(sp)
    800022f8:	1800                	addi	s0,sp,48
    800022fa:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022fc:	0000f497          	auipc	s1,0xf
    80002300:	cf448493          	addi	s1,s1,-780 # 80010ff0 <proc>
    80002304:	00015997          	auipc	s3,0x15
    80002308:	aec98993          	addi	s3,s3,-1300 # 80016df0 <tickslock>
    acquire(&p->lock);
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	8dc080e7          	jalr	-1828(ra) # 80000bea <acquire>
    if(p->pid == pid){
    80002316:	589c                	lw	a5,48(s1)
    80002318:	01278d63          	beq	a5,s2,80002332 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000231c:	8526                	mv	a0,s1
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	980080e7          	jalr	-1664(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002326:	17848493          	addi	s1,s1,376
    8000232a:	ff3491e3          	bne	s1,s3,8000230c <kill+0x20>
  }
  return -1;
    8000232e:	557d                	li	a0,-1
    80002330:	a829                	j	8000234a <kill+0x5e>
      p->killed = 1;
    80002332:	4785                	li	a5,1
    80002334:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002336:	4c98                	lw	a4,24(s1)
    80002338:	4789                	li	a5,2
    8000233a:	00f70f63          	beq	a4,a5,80002358 <kill+0x6c>
      release(&p->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	95e080e7          	jalr	-1698(ra) # 80000c9e <release>
      return 0;
    80002348:	4501                	li	a0,0
}
    8000234a:	70a2                	ld	ra,40(sp)
    8000234c:	7402                	ld	s0,32(sp)
    8000234e:	64e2                	ld	s1,24(sp)
    80002350:	6942                	ld	s2,16(sp)
    80002352:	69a2                	ld	s3,8(sp)
    80002354:	6145                	addi	sp,sp,48
    80002356:	8082                	ret
        p->state = RUNNABLE;
    80002358:	478d                	li	a5,3
    8000235a:	cc9c                	sw	a5,24(s1)
    8000235c:	b7cd                	j	8000233e <kill+0x52>

000000008000235e <setkilled>:

void
setkilled(struct proc *p)
{
    8000235e:	1101                	addi	sp,sp,-32
    80002360:	ec06                	sd	ra,24(sp)
    80002362:	e822                	sd	s0,16(sp)
    80002364:	e426                	sd	s1,8(sp)
    80002366:	1000                	addi	s0,sp,32
    80002368:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	880080e7          	jalr	-1920(ra) # 80000bea <acquire>
  p->killed = 1;
    80002372:	4785                	li	a5,1
    80002374:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	926080e7          	jalr	-1754(ra) # 80000c9e <release>
}
    80002380:	60e2                	ld	ra,24(sp)
    80002382:	6442                	ld	s0,16(sp)
    80002384:	64a2                	ld	s1,8(sp)
    80002386:	6105                	addi	sp,sp,32
    80002388:	8082                	ret

000000008000238a <killed>:

int
killed(struct proc *p)
{
    8000238a:	1101                	addi	sp,sp,-32
    8000238c:	ec06                	sd	ra,24(sp)
    8000238e:	e822                	sd	s0,16(sp)
    80002390:	e426                	sd	s1,8(sp)
    80002392:	e04a                	sd	s2,0(sp)
    80002394:	1000                	addi	s0,sp,32
    80002396:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	852080e7          	jalr	-1966(ra) # 80000bea <acquire>
  k = p->killed;
    800023a0:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	8f8080e7          	jalr	-1800(ra) # 80000c9e <release>
  return k;
}
    800023ae:	854a                	mv	a0,s2
    800023b0:	60e2                	ld	ra,24(sp)
    800023b2:	6442                	ld	s0,16(sp)
    800023b4:	64a2                	ld	s1,8(sp)
    800023b6:	6902                	ld	s2,0(sp)
    800023b8:	6105                	addi	sp,sp,32
    800023ba:	8082                	ret

00000000800023bc <wait>:
{
    800023bc:	715d                	addi	sp,sp,-80
    800023be:	e486                	sd	ra,72(sp)
    800023c0:	e0a2                	sd	s0,64(sp)
    800023c2:	fc26                	sd	s1,56(sp)
    800023c4:	f84a                	sd	s2,48(sp)
    800023c6:	f44e                	sd	s3,40(sp)
    800023c8:	f052                	sd	s4,32(sp)
    800023ca:	ec56                	sd	s5,24(sp)
    800023cc:	e85a                	sd	s6,16(sp)
    800023ce:	e45e                	sd	s7,8(sp)
    800023d0:	e062                	sd	s8,0(sp)
    800023d2:	0880                	addi	s0,sp,80
    800023d4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	5f0080e7          	jalr	1520(ra) # 800019c6 <myproc>
    800023de:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023e0:	0000e517          	auipc	a0,0xe
    800023e4:	7f850513          	addi	a0,a0,2040 # 80010bd8 <wait_lock>
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	802080e7          	jalr	-2046(ra) # 80000bea <acquire>
    havekids = 0;
    800023f0:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023f2:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f4:	00015997          	auipc	s3,0x15
    800023f8:	9fc98993          	addi	s3,s3,-1540 # 80016df0 <tickslock>
        havekids = 1;
    800023fc:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023fe:	0000ec17          	auipc	s8,0xe
    80002402:	7dac0c13          	addi	s8,s8,2010 # 80010bd8 <wait_lock>
    havekids = 0;
    80002406:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002408:	0000f497          	auipc	s1,0xf
    8000240c:	be848493          	addi	s1,s1,-1048 # 80010ff0 <proc>
    80002410:	a0bd                	j	8000247e <wait+0xc2>
          pid = pp->pid;
    80002412:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002416:	000b0e63          	beqz	s6,80002432 <wait+0x76>
    8000241a:	4691                	li	a3,4
    8000241c:	02c48613          	addi	a2,s1,44
    80002420:	85da                	mv	a1,s6
    80002422:	06093503          	ld	a0,96(s2)
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	25e080e7          	jalr	606(ra) # 80001684 <copyout>
    8000242e:	02054563          	bltz	a0,80002458 <wait+0x9c>
          freeproc(pp);
    80002432:	8526                	mv	a0,s1
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	744080e7          	jalr	1860(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	860080e7          	jalr	-1952(ra) # 80000c9e <release>
          release(&wait_lock);
    80002446:	0000e517          	auipc	a0,0xe
    8000244a:	79250513          	addi	a0,a0,1938 # 80010bd8 <wait_lock>
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	850080e7          	jalr	-1968(ra) # 80000c9e <release>
          return pid;
    80002456:	a0b5                	j	800024c2 <wait+0x106>
            release(&pp->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	844080e7          	jalr	-1980(ra) # 80000c9e <release>
            release(&wait_lock);
    80002462:	0000e517          	auipc	a0,0xe
    80002466:	77650513          	addi	a0,a0,1910 # 80010bd8 <wait_lock>
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	834080e7          	jalr	-1996(ra) # 80000c9e <release>
            return -1;
    80002472:	59fd                	li	s3,-1
    80002474:	a0b9                	j	800024c2 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002476:	17848493          	addi	s1,s1,376
    8000247a:	03348463          	beq	s1,s3,800024a2 <wait+0xe6>
      if(pp->parent == p){
    8000247e:	64bc                	ld	a5,72(s1)
    80002480:	ff279be3          	bne	a5,s2,80002476 <wait+0xba>
        acquire(&pp->lock);
    80002484:	8526                	mv	a0,s1
    80002486:	ffffe097          	auipc	ra,0xffffe
    8000248a:	764080e7          	jalr	1892(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    8000248e:	4c9c                	lw	a5,24(s1)
    80002490:	f94781e3          	beq	a5,s4,80002412 <wait+0x56>
        release(&pp->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	808080e7          	jalr	-2040(ra) # 80000c9e <release>
        havekids = 1;
    8000249e:	8756                	mv	a4,s5
    800024a0:	bfd9                	j	80002476 <wait+0xba>
    if(!havekids || killed(p)){
    800024a2:	c719                	beqz	a4,800024b0 <wait+0xf4>
    800024a4:	854a                	mv	a0,s2
    800024a6:	00000097          	auipc	ra,0x0
    800024aa:	ee4080e7          	jalr	-284(ra) # 8000238a <killed>
    800024ae:	c51d                	beqz	a0,800024dc <wait+0x120>
      release(&wait_lock);
    800024b0:	0000e517          	auipc	a0,0xe
    800024b4:	72850513          	addi	a0,a0,1832 # 80010bd8 <wait_lock>
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	7e6080e7          	jalr	2022(ra) # 80000c9e <release>
      return -1;
    800024c0:	59fd                	li	s3,-1
}
    800024c2:	854e                	mv	a0,s3
    800024c4:	60a6                	ld	ra,72(sp)
    800024c6:	6406                	ld	s0,64(sp)
    800024c8:	74e2                	ld	s1,56(sp)
    800024ca:	7942                	ld	s2,48(sp)
    800024cc:	79a2                	ld	s3,40(sp)
    800024ce:	7a02                	ld	s4,32(sp)
    800024d0:	6ae2                	ld	s5,24(sp)
    800024d2:	6b42                	ld	s6,16(sp)
    800024d4:	6ba2                	ld	s7,8(sp)
    800024d6:	6c02                	ld	s8,0(sp)
    800024d8:	6161                	addi	sp,sp,80
    800024da:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024dc:	85e2                	mv	a1,s8
    800024de:	854a                	mv	a0,s2
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	c02080e7          	jalr	-1022(ra) # 800020e2 <sleep>
    havekids = 0;
    800024e8:	bf39                	j	80002406 <wait+0x4a>

00000000800024ea <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024ea:	7179                	addi	sp,sp,-48
    800024ec:	f406                	sd	ra,40(sp)
    800024ee:	f022                	sd	s0,32(sp)
    800024f0:	ec26                	sd	s1,24(sp)
    800024f2:	e84a                	sd	s2,16(sp)
    800024f4:	e44e                	sd	s3,8(sp)
    800024f6:	e052                	sd	s4,0(sp)
    800024f8:	1800                	addi	s0,sp,48
    800024fa:	84aa                	mv	s1,a0
    800024fc:	892e                	mv	s2,a1
    800024fe:	89b2                	mv	s3,a2
    80002500:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	4c4080e7          	jalr	1220(ra) # 800019c6 <myproc>
  if(user_dst){
    8000250a:	c08d                	beqz	s1,8000252c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000250c:	86d2                	mv	a3,s4
    8000250e:	864e                	mv	a2,s3
    80002510:	85ca                	mv	a1,s2
    80002512:	7128                	ld	a0,96(a0)
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	170080e7          	jalr	368(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000251c:	70a2                	ld	ra,40(sp)
    8000251e:	7402                	ld	s0,32(sp)
    80002520:	64e2                	ld	s1,24(sp)
    80002522:	6942                	ld	s2,16(sp)
    80002524:	69a2                	ld	s3,8(sp)
    80002526:	6a02                	ld	s4,0(sp)
    80002528:	6145                	addi	sp,sp,48
    8000252a:	8082                	ret
    memmove((char *)dst, src, len);
    8000252c:	000a061b          	sext.w	a2,s4
    80002530:	85ce                	mv	a1,s3
    80002532:	854a                	mv	a0,s2
    80002534:	fffff097          	auipc	ra,0xfffff
    80002538:	812080e7          	jalr	-2030(ra) # 80000d46 <memmove>
    return 0;
    8000253c:	8526                	mv	a0,s1
    8000253e:	bff9                	j	8000251c <either_copyout+0x32>

0000000080002540 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002540:	7179                	addi	sp,sp,-48
    80002542:	f406                	sd	ra,40(sp)
    80002544:	f022                	sd	s0,32(sp)
    80002546:	ec26                	sd	s1,24(sp)
    80002548:	e84a                	sd	s2,16(sp)
    8000254a:	e44e                	sd	s3,8(sp)
    8000254c:	e052                	sd	s4,0(sp)
    8000254e:	1800                	addi	s0,sp,48
    80002550:	892a                	mv	s2,a0
    80002552:	84ae                	mv	s1,a1
    80002554:	89b2                	mv	s3,a2
    80002556:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002558:	fffff097          	auipc	ra,0xfffff
    8000255c:	46e080e7          	jalr	1134(ra) # 800019c6 <myproc>
  if(user_src){
    80002560:	c08d                	beqz	s1,80002582 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002562:	86d2                	mv	a3,s4
    80002564:	864e                	mv	a2,s3
    80002566:	85ca                	mv	a1,s2
    80002568:	7128                	ld	a0,96(a0)
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	1a6080e7          	jalr	422(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002572:	70a2                	ld	ra,40(sp)
    80002574:	7402                	ld	s0,32(sp)
    80002576:	64e2                	ld	s1,24(sp)
    80002578:	6942                	ld	s2,16(sp)
    8000257a:	69a2                	ld	s3,8(sp)
    8000257c:	6a02                	ld	s4,0(sp)
    8000257e:	6145                	addi	sp,sp,48
    80002580:	8082                	ret
    memmove(dst, (char*)src, len);
    80002582:	000a061b          	sext.w	a2,s4
    80002586:	85ce                	mv	a1,s3
    80002588:	854a                	mv	a0,s2
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	7bc080e7          	jalr	1980(ra) # 80000d46 <memmove>
    return 0;
    80002592:	8526                	mv	a0,s1
    80002594:	bff9                	j	80002572 <either_copyin+0x32>

0000000080002596 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002596:	715d                	addi	sp,sp,-80
    80002598:	e486                	sd	ra,72(sp)
    8000259a:	e0a2                	sd	s0,64(sp)
    8000259c:	fc26                	sd	s1,56(sp)
    8000259e:	f84a                	sd	s2,48(sp)
    800025a0:	f44e                	sd	s3,40(sp)
    800025a2:	f052                	sd	s4,32(sp)
    800025a4:	ec56                	sd	s5,24(sp)
    800025a6:	e85a                	sd	s6,16(sp)
    800025a8:	e45e                	sd	s7,8(sp)
    800025aa:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ac:	00006517          	auipc	a0,0x6
    800025b0:	b1c50513          	addi	a0,a0,-1252 # 800080c8 <digits+0x88>
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	fda080e7          	jalr	-38(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025bc:	0000f497          	auipc	s1,0xf
    800025c0:	b9c48493          	addi	s1,s1,-1124 # 80011158 <proc+0x168>
    800025c4:	00015917          	auipc	s2,0x15
    800025c8:	99490913          	addi	s2,s2,-1644 # 80016f58 <bcache+0x150>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025cc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025ce:	00006997          	auipc	s3,0x6
    800025d2:	cb298993          	addi	s3,s3,-846 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025d6:	00006a97          	auipc	s5,0x6
    800025da:	cb2a8a93          	addi	s5,s5,-846 # 80008288 <digits+0x248>
    printf("\n");
    800025de:	00006a17          	auipc	s4,0x6
    800025e2:	aeaa0a13          	addi	s4,s4,-1302 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e6:	00006b97          	auipc	s7,0x6
    800025ea:	d3ab8b93          	addi	s7,s7,-710 # 80008320 <states.1733>
    800025ee:	a00d                	j	80002610 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025f0:	ec86a583          	lw	a1,-312(a3)
    800025f4:	8556                	mv	a0,s5
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	f98080e7          	jalr	-104(ra) # 8000058e <printf>
    printf("\n");
    800025fe:	8552                	mv	a0,s4
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	f8e080e7          	jalr	-114(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002608:	17848493          	addi	s1,s1,376
    8000260c:	03248163          	beq	s1,s2,8000262e <procdump+0x98>
    if(p->state == UNUSED)
    80002610:	86a6                	mv	a3,s1
    80002612:	eb04a783          	lw	a5,-336(s1)
    80002616:	dbed                	beqz	a5,80002608 <procdump+0x72>
      state = "???";
    80002618:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000261a:	fcfb6be3          	bltu	s6,a5,800025f0 <procdump+0x5a>
    8000261e:	1782                	slli	a5,a5,0x20
    80002620:	9381                	srli	a5,a5,0x20
    80002622:	078e                	slli	a5,a5,0x3
    80002624:	97de                	add	a5,a5,s7
    80002626:	6390                	ld	a2,0(a5)
    80002628:	f661                	bnez	a2,800025f0 <procdump+0x5a>
      state = "???";
    8000262a:	864e                	mv	a2,s3
    8000262c:	b7d1                	j	800025f0 <procdump+0x5a>
  }
}
    8000262e:	60a6                	ld	ra,72(sp)
    80002630:	6406                	ld	s0,64(sp)
    80002632:	74e2                	ld	s1,56(sp)
    80002634:	7942                	ld	s2,48(sp)
    80002636:	79a2                	ld	s3,40(sp)
    80002638:	7a02                	ld	s4,32(sp)
    8000263a:	6ae2                	ld	s5,24(sp)
    8000263c:	6b42                	ld	s6,16(sp)
    8000263e:	6ba2                	ld	s7,8(sp)
    80002640:	6161                	addi	sp,sp,80
    80002642:	8082                	ret

0000000080002644 <sched_statistics>:

int 
sched_statistics(void)
{
    80002644:	7179                	addi	sp,sp,-48
    80002646:	f406                	sd	ra,40(sp)
    80002648:	f022                	sd	s0,32(sp)
    8000264a:	ec26                	sd	s1,24(sp)
    8000264c:	e84a                	sd	s2,16(sp)
    8000264e:	e44e                	sd	s3,8(sp)
    80002650:	1800                	addi	s0,sp,48
  struct proc *p;
  //printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    80002652:	0000f497          	auipc	s1,0xf
    80002656:	99e48493          	addi	s1,s1,-1634 # 80010ff0 <proc>
    if(p->state != UNUSED){
      printf("%d(%s): tickets: %d, ticks: %d\n", p->pid, p->name, p->tickets, p->ticks);
    8000265a:	00006997          	auipc	s3,0x6
    8000265e:	c3e98993          	addi	s3,s3,-962 # 80008298 <digits+0x258>
  for(p = proc; p < &proc[NPROC]; p++){
    80002662:	00014917          	auipc	s2,0x14
    80002666:	78e90913          	addi	s2,s2,1934 # 80016df0 <tickslock>
    8000266a:	a839                	j	80002688 <sched_statistics+0x44>
      printf("%d(%s): tickets: %d, ticks: %d\n", p->pid, p->name, p->tickets, p->ticks);
    8000266c:	5c98                	lw	a4,56(s1)
    8000266e:	58d4                	lw	a3,52(s1)
    80002670:	16848613          	addi	a2,s1,360
    80002674:	588c                	lw	a1,48(s1)
    80002676:	854e                	mv	a0,s3
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	f16080e7          	jalr	-234(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002680:	17848493          	addi	s1,s1,376
    80002684:	01248563          	beq	s1,s2,8000268e <sched_statistics+0x4a>
    if(p->state != UNUSED){
    80002688:	4c9c                	lw	a5,24(s1)
    8000268a:	dbfd                	beqz	a5,80002680 <sched_statistics+0x3c>
    8000268c:	b7c5                	j	8000266c <sched_statistics+0x28>
    }
  }
  return 0;
}
    8000268e:	4501                	li	a0,0
    80002690:	70a2                	ld	ra,40(sp)
    80002692:	7402                	ld	s0,32(sp)
    80002694:	64e2                	ld	s1,24(sp)
    80002696:	6942                	ld	s2,16(sp)
    80002698:	69a2                	ld	s3,8(sp)
    8000269a:	6145                	addi	sp,sp,48
    8000269c:	8082                	ret

000000008000269e <sched_tickets>:

int
sched_tickets(int n)
{
    8000269e:	1101                	addi	sp,sp,-32
    800026a0:	ec06                	sd	ra,24(sp)
    800026a2:	e822                	sd	s0,16(sp)
    800026a4:	e426                	sd	s1,8(sp)
    800026a6:	1000                	addi	s0,sp,32
    800026a8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	31c080e7          	jalr	796(ra) # 800019c6 <myproc>
  if(n > 10000)
    800026b2:	8626                	mv	a2,s1
    800026b4:	6789                	lui	a5,0x2
    800026b6:	71078793          	addi	a5,a5,1808 # 2710 <_entry-0x7fffd8f0>
    800026ba:	0097d563          	bge	a5,s1,800026c4 <sched_tickets+0x26>
    800026be:	6609                	lui	a2,0x2
    800026c0:	7106061b          	addiw	a2,a2,1808
    n = 10000;
  p->tickets = n;
    800026c4:	d950                	sw	a2,52(a0)
  p->stride = BIG_NUM / p->tickets;
    800026c6:	66e1                	lui	a3,0x18
    800026c8:	6a06869b          	addiw	a3,a3,1696
    800026cc:	02c6c6bb          	divw	a3,a3,a2
    800026d0:	dd54                	sw	a3,60(a0)
  printf("sched_tickets: pid %d set tickets = %d, stride = %d\n", p->pid, p->tickets, p->stride);
    800026d2:	2681                	sext.w	a3,a3
    800026d4:	2601                	sext.w	a2,a2
    800026d6:	590c                	lw	a1,48(a0)
    800026d8:	00006517          	auipc	a0,0x6
    800026dc:	be050513          	addi	a0,a0,-1056 # 800082b8 <digits+0x278>
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	eae080e7          	jalr	-338(ra) # 8000058e <printf>
  return 0;
    800026e8:	4501                	li	a0,0
    800026ea:	60e2                	ld	ra,24(sp)
    800026ec:	6442                	ld	s0,16(sp)
    800026ee:	64a2                	ld	s1,8(sp)
    800026f0:	6105                	addi	sp,sp,32
    800026f2:	8082                	ret

00000000800026f4 <swtch>:
    800026f4:	00153023          	sd	ra,0(a0)
    800026f8:	00253423          	sd	sp,8(a0)
    800026fc:	e900                	sd	s0,16(a0)
    800026fe:	ed04                	sd	s1,24(a0)
    80002700:	03253023          	sd	s2,32(a0)
    80002704:	03353423          	sd	s3,40(a0)
    80002708:	03453823          	sd	s4,48(a0)
    8000270c:	03553c23          	sd	s5,56(a0)
    80002710:	05653023          	sd	s6,64(a0)
    80002714:	05753423          	sd	s7,72(a0)
    80002718:	05853823          	sd	s8,80(a0)
    8000271c:	05953c23          	sd	s9,88(a0)
    80002720:	07a53023          	sd	s10,96(a0)
    80002724:	07b53423          	sd	s11,104(a0)
    80002728:	0005b083          	ld	ra,0(a1)
    8000272c:	0085b103          	ld	sp,8(a1)
    80002730:	6980                	ld	s0,16(a1)
    80002732:	6d84                	ld	s1,24(a1)
    80002734:	0205b903          	ld	s2,32(a1)
    80002738:	0285b983          	ld	s3,40(a1)
    8000273c:	0305ba03          	ld	s4,48(a1)
    80002740:	0385ba83          	ld	s5,56(a1)
    80002744:	0405bb03          	ld	s6,64(a1)
    80002748:	0485bb83          	ld	s7,72(a1)
    8000274c:	0505bc03          	ld	s8,80(a1)
    80002750:	0585bc83          	ld	s9,88(a1)
    80002754:	0605bd03          	ld	s10,96(a1)
    80002758:	0685bd83          	ld	s11,104(a1)
    8000275c:	8082                	ret

000000008000275e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000275e:	1141                	addi	sp,sp,-16
    80002760:	e406                	sd	ra,8(sp)
    80002762:	e022                	sd	s0,0(sp)
    80002764:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002766:	00006597          	auipc	a1,0x6
    8000276a:	bea58593          	addi	a1,a1,-1046 # 80008350 <states.1733+0x30>
    8000276e:	00014517          	auipc	a0,0x14
    80002772:	68250513          	addi	a0,a0,1666 # 80016df0 <tickslock>
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	3e4080e7          	jalr	996(ra) # 80000b5a <initlock>
}
    8000277e:	60a2                	ld	ra,8(sp)
    80002780:	6402                	ld	s0,0(sp)
    80002782:	0141                	addi	sp,sp,16
    80002784:	8082                	ret

0000000080002786 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002786:	1141                	addi	sp,sp,-16
    80002788:	e422                	sd	s0,8(sp)
    8000278a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000278c:	00003797          	auipc	a5,0x3
    80002790:	51478793          	addi	a5,a5,1300 # 80005ca0 <kernelvec>
    80002794:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002798:	6422                	ld	s0,8(sp)
    8000279a:	0141                	addi	sp,sp,16
    8000279c:	8082                	ret

000000008000279e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000279e:	1141                	addi	sp,sp,-16
    800027a0:	e406                	sd	ra,8(sp)
    800027a2:	e022                	sd	s0,0(sp)
    800027a4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027a6:	fffff097          	auipc	ra,0xfffff
    800027aa:	220080e7          	jalr	544(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027b2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027b4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027b8:	00005617          	auipc	a2,0x5
    800027bc:	84860613          	addi	a2,a2,-1976 # 80007000 <_trampoline>
    800027c0:	00005697          	auipc	a3,0x5
    800027c4:	84068693          	addi	a3,a3,-1984 # 80007000 <_trampoline>
    800027c8:	8e91                	sub	a3,a3,a2
    800027ca:	040007b7          	lui	a5,0x4000
    800027ce:	17fd                	addi	a5,a5,-1
    800027d0:	07b2                	slli	a5,a5,0xc
    800027d2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027d4:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027d8:	7538                	ld	a4,104(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027da:	180026f3          	csrr	a3,satp
    800027de:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027e0:	7538                	ld	a4,104(a0)
    800027e2:	6934                	ld	a3,80(a0)
    800027e4:	6585                	lui	a1,0x1
    800027e6:	96ae                	add	a3,a3,a1
    800027e8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027ea:	7538                	ld	a4,104(a0)
    800027ec:	00000697          	auipc	a3,0x0
    800027f0:	15268693          	addi	a3,a3,338 # 8000293e <usertrap>
    800027f4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027f6:	7538                	ld	a4,104(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027f8:	8692                	mv	a3,tp
    800027fa:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027fc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002800:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002804:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002808:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000280c:	7538                	ld	a4,104(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000280e:	6f18                	ld	a4,24(a4)
    80002810:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002814:	7128                	ld	a0,96(a0)
    80002816:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002818:	00005717          	auipc	a4,0x5
    8000281c:	88470713          	addi	a4,a4,-1916 # 8000709c <userret>
    80002820:	8f11                	sub	a4,a4,a2
    80002822:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002824:	577d                	li	a4,-1
    80002826:	177e                	slli	a4,a4,0x3f
    80002828:	8d59                	or	a0,a0,a4
    8000282a:	9782                	jalr	a5
}
    8000282c:	60a2                	ld	ra,8(sp)
    8000282e:	6402                	ld	s0,0(sp)
    80002830:	0141                	addi	sp,sp,16
    80002832:	8082                	ret

0000000080002834 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002834:	1141                	addi	sp,sp,-16
    80002836:	e406                	sd	ra,8(sp)
    80002838:	e022                	sd	s0,0(sp)
    8000283a:	0800                	addi	s0,sp,16
  acquire(&tickslock);
    8000283c:	00014517          	auipc	a0,0x14
    80002840:	5b450513          	addi	a0,a0,1460 # 80016df0 <tickslock>
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	3a6080e7          	jalr	934(ra) # 80000bea <acquire>
  ticks++;
    8000284c:	00006717          	auipc	a4,0x6
    80002850:	10470713          	addi	a4,a4,260 # 80008950 <ticks>
    80002854:	431c                	lw	a5,0(a4)
    80002856:	2785                	addiw	a5,a5,1
    80002858:	c31c                	sw	a5,0(a4)

  struct proc *p = myproc();
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	16c080e7          	jalr	364(ra) # 800019c6 <myproc>
  if(p && p->state == RUNNING){
    80002862:	c509                	beqz	a0,8000286c <clockintr+0x38>
    80002864:	4d18                	lw	a4,24(a0)
    80002866:	4791                	li	a5,4
    80002868:	02f70663          	beq	a4,a5,80002894 <clockintr+0x60>
    p->ticks++;
  }


  wakeup(&ticks);
    8000286c:	00006517          	auipc	a0,0x6
    80002870:	0e450513          	addi	a0,a0,228 # 80008950 <ticks>
    80002874:	00000097          	auipc	ra,0x0
    80002878:	8d2080e7          	jalr	-1838(ra) # 80002146 <wakeup>
  release(&tickslock);
    8000287c:	00014517          	auipc	a0,0x14
    80002880:	57450513          	addi	a0,a0,1396 # 80016df0 <tickslock>
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	41a080e7          	jalr	1050(ra) # 80000c9e <release>
}
    8000288c:	60a2                	ld	ra,8(sp)
    8000288e:	6402                	ld	s0,0(sp)
    80002890:	0141                	addi	sp,sp,16
    80002892:	8082                	ret
    p->ticks++;
    80002894:	5d1c                	lw	a5,56(a0)
    80002896:	2785                	addiw	a5,a5,1
    80002898:	dd1c                	sw	a5,56(a0)
    8000289a:	bfc9                	j	8000286c <clockintr+0x38>

000000008000289c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000289c:	1101                	addi	sp,sp,-32
    8000289e:	ec06                	sd	ra,24(sp)
    800028a0:	e822                	sd	s0,16(sp)
    800028a2:	e426                	sd	s1,8(sp)
    800028a4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028a6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028aa:	00074d63          	bltz	a4,800028c4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028ae:	57fd                	li	a5,-1
    800028b0:	17fe                	slli	a5,a5,0x3f
    800028b2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028b4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028b6:	06f70363          	beq	a4,a5,8000291c <devintr+0x80>
  }
}
    800028ba:	60e2                	ld	ra,24(sp)
    800028bc:	6442                	ld	s0,16(sp)
    800028be:	64a2                	ld	s1,8(sp)
    800028c0:	6105                	addi	sp,sp,32
    800028c2:	8082                	ret
     (scause & 0xff) == 9){
    800028c4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028c8:	46a5                	li	a3,9
    800028ca:	fed792e3          	bne	a5,a3,800028ae <devintr+0x12>
    int irq = plic_claim();
    800028ce:	00003097          	auipc	ra,0x3
    800028d2:	4da080e7          	jalr	1242(ra) # 80005da8 <plic_claim>
    800028d6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028d8:	47a9                	li	a5,10
    800028da:	02f50763          	beq	a0,a5,80002908 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028de:	4785                	li	a5,1
    800028e0:	02f50963          	beq	a0,a5,80002912 <devintr+0x76>
    return 1;
    800028e4:	4505                	li	a0,1
    } else if(irq){
    800028e6:	d8f1                	beqz	s1,800028ba <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028e8:	85a6                	mv	a1,s1
    800028ea:	00006517          	auipc	a0,0x6
    800028ee:	a6e50513          	addi	a0,a0,-1426 # 80008358 <states.1733+0x38>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	c9c080e7          	jalr	-868(ra) # 8000058e <printf>
      plic_complete(irq);
    800028fa:	8526                	mv	a0,s1
    800028fc:	00003097          	auipc	ra,0x3
    80002900:	4d0080e7          	jalr	1232(ra) # 80005dcc <plic_complete>
    return 1;
    80002904:	4505                	li	a0,1
    80002906:	bf55                	j	800028ba <devintr+0x1e>
      uartintr();
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	0a6080e7          	jalr	166(ra) # 800009ae <uartintr>
    80002910:	b7ed                	j	800028fa <devintr+0x5e>
      virtio_disk_intr();
    80002912:	00004097          	auipc	ra,0x4
    80002916:	9e4080e7          	jalr	-1564(ra) # 800062f6 <virtio_disk_intr>
    8000291a:	b7c5                	j	800028fa <devintr+0x5e>
    if(cpuid() == 0){
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	07e080e7          	jalr	126(ra) # 8000199a <cpuid>
    80002924:	c901                	beqz	a0,80002934 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002926:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000292a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000292c:	14479073          	csrw	sip,a5
    return 2;
    80002930:	4509                	li	a0,2
    80002932:	b761                	j	800028ba <devintr+0x1e>
      clockintr();
    80002934:	00000097          	auipc	ra,0x0
    80002938:	f00080e7          	jalr	-256(ra) # 80002834 <clockintr>
    8000293c:	b7ed                	j	80002926 <devintr+0x8a>

000000008000293e <usertrap>:
{
    8000293e:	1101                	addi	sp,sp,-32
    80002940:	ec06                	sd	ra,24(sp)
    80002942:	e822                	sd	s0,16(sp)
    80002944:	e426                	sd	s1,8(sp)
    80002946:	e04a                	sd	s2,0(sp)
    80002948:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000294a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000294e:	1007f793          	andi	a5,a5,256
    80002952:	e3b1                	bnez	a5,80002996 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002954:	00003797          	auipc	a5,0x3
    80002958:	34c78793          	addi	a5,a5,844 # 80005ca0 <kernelvec>
    8000295c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002960:	fffff097          	auipc	ra,0xfffff
    80002964:	066080e7          	jalr	102(ra) # 800019c6 <myproc>
    80002968:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000296a:	753c                	ld	a5,104(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000296c:	14102773          	csrr	a4,sepc
    80002970:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002972:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002976:	47a1                	li	a5,8
    80002978:	02f70763          	beq	a4,a5,800029a6 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	f20080e7          	jalr	-224(ra) # 8000289c <devintr>
    80002984:	892a                	mv	s2,a0
    80002986:	c151                	beqz	a0,80002a0a <usertrap+0xcc>
  if(killed(p))
    80002988:	8526                	mv	a0,s1
    8000298a:	00000097          	auipc	ra,0x0
    8000298e:	a00080e7          	jalr	-1536(ra) # 8000238a <killed>
    80002992:	c929                	beqz	a0,800029e4 <usertrap+0xa6>
    80002994:	a099                	j	800029da <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002996:	00006517          	auipc	a0,0x6
    8000299a:	9e250513          	addi	a0,a0,-1566 # 80008378 <states.1733+0x58>
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	ba6080e7          	jalr	-1114(ra) # 80000544 <panic>
    if(killed(p))
    800029a6:	00000097          	auipc	ra,0x0
    800029aa:	9e4080e7          	jalr	-1564(ra) # 8000238a <killed>
    800029ae:	e921                	bnez	a0,800029fe <usertrap+0xc0>
    p->trapframe->epc += 4;
    800029b0:	74b8                	ld	a4,104(s1)
    800029b2:	6f1c                	ld	a5,24(a4)
    800029b4:	0791                	addi	a5,a5,4
    800029b6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029bc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c0:	10079073          	csrw	sstatus,a5
    syscall();
    800029c4:	00000097          	auipc	ra,0x0
    800029c8:	2d4080e7          	jalr	724(ra) # 80002c98 <syscall>
  if(killed(p))
    800029cc:	8526                	mv	a0,s1
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	9bc080e7          	jalr	-1604(ra) # 8000238a <killed>
    800029d6:	c911                	beqz	a0,800029ea <usertrap+0xac>
    800029d8:	4901                	li	s2,0
    exit(-1);
    800029da:	557d                	li	a0,-1
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	83a080e7          	jalr	-1990(ra) # 80002216 <exit>
  if(which_dev == 2)
    800029e4:	4789                	li	a5,2
    800029e6:	04f90f63          	beq	s2,a5,80002a44 <usertrap+0x106>
  usertrapret();
    800029ea:	00000097          	auipc	ra,0x0
    800029ee:	db4080e7          	jalr	-588(ra) # 8000279e <usertrapret>
}
    800029f2:	60e2                	ld	ra,24(sp)
    800029f4:	6442                	ld	s0,16(sp)
    800029f6:	64a2                	ld	s1,8(sp)
    800029f8:	6902                	ld	s2,0(sp)
    800029fa:	6105                	addi	sp,sp,32
    800029fc:	8082                	ret
      exit(-1);
    800029fe:	557d                	li	a0,-1
    80002a00:	00000097          	auipc	ra,0x0
    80002a04:	816080e7          	jalr	-2026(ra) # 80002216 <exit>
    80002a08:	b765                	j	800029b0 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a0e:	5890                	lw	a2,48(s1)
    80002a10:	00006517          	auipc	a0,0x6
    80002a14:	98850513          	addi	a0,a0,-1656 # 80008398 <states.1733+0x78>
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	b76080e7          	jalr	-1162(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a20:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a24:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a28:	00006517          	auipc	a0,0x6
    80002a2c:	9a050513          	addi	a0,a0,-1632 # 800083c8 <states.1733+0xa8>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	b5e080e7          	jalr	-1186(ra) # 8000058e <printf>
    setkilled(p);
    80002a38:	8526                	mv	a0,s1
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	924080e7          	jalr	-1756(ra) # 8000235e <setkilled>
    80002a42:	b769                	j	800029cc <usertrap+0x8e>
    yield();
    80002a44:	fffff097          	auipc	ra,0xfffff
    80002a48:	662080e7          	jalr	1634(ra) # 800020a6 <yield>
    80002a4c:	bf79                	j	800029ea <usertrap+0xac>

0000000080002a4e <kerneltrap>:
{
    80002a4e:	7179                	addi	sp,sp,-48
    80002a50:	f406                	sd	ra,40(sp)
    80002a52:	f022                	sd	s0,32(sp)
    80002a54:	ec26                	sd	s1,24(sp)
    80002a56:	e84a                	sd	s2,16(sp)
    80002a58:	e44e                	sd	s3,8(sp)
    80002a5a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a5c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a60:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a64:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a68:	1004f793          	andi	a5,s1,256
    80002a6c:	cb85                	beqz	a5,80002a9c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a72:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a74:	ef85                	bnez	a5,80002aac <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a76:	00000097          	auipc	ra,0x0
    80002a7a:	e26080e7          	jalr	-474(ra) # 8000289c <devintr>
    80002a7e:	cd1d                	beqz	a0,80002abc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a80:	4789                	li	a5,2
    80002a82:	06f50a63          	beq	a0,a5,80002af6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a86:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a8a:	10049073          	csrw	sstatus,s1
}
    80002a8e:	70a2                	ld	ra,40(sp)
    80002a90:	7402                	ld	s0,32(sp)
    80002a92:	64e2                	ld	s1,24(sp)
    80002a94:	6942                	ld	s2,16(sp)
    80002a96:	69a2                	ld	s3,8(sp)
    80002a98:	6145                	addi	sp,sp,48
    80002a9a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a9c:	00006517          	auipc	a0,0x6
    80002aa0:	94c50513          	addi	a0,a0,-1716 # 800083e8 <states.1733+0xc8>
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	aa0080e7          	jalr	-1376(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002aac:	00006517          	auipc	a0,0x6
    80002ab0:	96450513          	addi	a0,a0,-1692 # 80008410 <states.1733+0xf0>
    80002ab4:	ffffe097          	auipc	ra,0xffffe
    80002ab8:	a90080e7          	jalr	-1392(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002abc:	85ce                	mv	a1,s3
    80002abe:	00006517          	auipc	a0,0x6
    80002ac2:	97250513          	addi	a0,a0,-1678 # 80008430 <states.1733+0x110>
    80002ac6:	ffffe097          	auipc	ra,0xffffe
    80002aca:	ac8080e7          	jalr	-1336(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ace:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ad2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ad6:	00006517          	auipc	a0,0x6
    80002ada:	96a50513          	addi	a0,a0,-1686 # 80008440 <states.1733+0x120>
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	ab0080e7          	jalr	-1360(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002ae6:	00006517          	auipc	a0,0x6
    80002aea:	97250513          	addi	a0,a0,-1678 # 80008458 <states.1733+0x138>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	a56080e7          	jalr	-1450(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	ed0080e7          	jalr	-304(ra) # 800019c6 <myproc>
    80002afe:	d541                	beqz	a0,80002a86 <kerneltrap+0x38>
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	ec6080e7          	jalr	-314(ra) # 800019c6 <myproc>
    80002b08:	4d18                	lw	a4,24(a0)
    80002b0a:	4791                	li	a5,4
    80002b0c:	f6f71de3          	bne	a4,a5,80002a86 <kerneltrap+0x38>
    yield();
    80002b10:	fffff097          	auipc	ra,0xfffff
    80002b14:	596080e7          	jalr	1430(ra) # 800020a6 <yield>
    80002b18:	b7bd                	j	80002a86 <kerneltrap+0x38>

0000000080002b1a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b1a:	1101                	addi	sp,sp,-32
    80002b1c:	ec06                	sd	ra,24(sp)
    80002b1e:	e822                	sd	s0,16(sp)
    80002b20:	e426                	sd	s1,8(sp)
    80002b22:	1000                	addi	s0,sp,32
    80002b24:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	ea0080e7          	jalr	-352(ra) # 800019c6 <myproc>
  switch (n) {
    80002b2e:	4795                	li	a5,5
    80002b30:	0497e163          	bltu	a5,s1,80002b72 <argraw+0x58>
    80002b34:	048a                	slli	s1,s1,0x2
    80002b36:	00006717          	auipc	a4,0x6
    80002b3a:	95a70713          	addi	a4,a4,-1702 # 80008490 <states.1733+0x170>
    80002b3e:	94ba                	add	s1,s1,a4
    80002b40:	409c                	lw	a5,0(s1)
    80002b42:	97ba                	add	a5,a5,a4
    80002b44:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b46:	753c                	ld	a5,104(a0)
    80002b48:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b4a:	60e2                	ld	ra,24(sp)
    80002b4c:	6442                	ld	s0,16(sp)
    80002b4e:	64a2                	ld	s1,8(sp)
    80002b50:	6105                	addi	sp,sp,32
    80002b52:	8082                	ret
    return p->trapframe->a1;
    80002b54:	753c                	ld	a5,104(a0)
    80002b56:	7fa8                	ld	a0,120(a5)
    80002b58:	bfcd                	j	80002b4a <argraw+0x30>
    return p->trapframe->a2;
    80002b5a:	753c                	ld	a5,104(a0)
    80002b5c:	63c8                	ld	a0,128(a5)
    80002b5e:	b7f5                	j	80002b4a <argraw+0x30>
    return p->trapframe->a3;
    80002b60:	753c                	ld	a5,104(a0)
    80002b62:	67c8                	ld	a0,136(a5)
    80002b64:	b7dd                	j	80002b4a <argraw+0x30>
    return p->trapframe->a4;
    80002b66:	753c                	ld	a5,104(a0)
    80002b68:	6bc8                	ld	a0,144(a5)
    80002b6a:	b7c5                	j	80002b4a <argraw+0x30>
    return p->trapframe->a5;
    80002b6c:	753c                	ld	a5,104(a0)
    80002b6e:	6fc8                	ld	a0,152(a5)
    80002b70:	bfe9                	j	80002b4a <argraw+0x30>
  panic("argraw");
    80002b72:	00006517          	auipc	a0,0x6
    80002b76:	8f650513          	addi	a0,a0,-1802 # 80008468 <states.1733+0x148>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	9ca080e7          	jalr	-1590(ra) # 80000544 <panic>

0000000080002b82 <fetchaddr>:
{
    80002b82:	1101                	addi	sp,sp,-32
    80002b84:	ec06                	sd	ra,24(sp)
    80002b86:	e822                	sd	s0,16(sp)
    80002b88:	e426                	sd	s1,8(sp)
    80002b8a:	e04a                	sd	s2,0(sp)
    80002b8c:	1000                	addi	s0,sp,32
    80002b8e:	84aa                	mv	s1,a0
    80002b90:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	e34080e7          	jalr	-460(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b9a:	6d3c                	ld	a5,88(a0)
    80002b9c:	02f4f863          	bgeu	s1,a5,80002bcc <fetchaddr+0x4a>
    80002ba0:	00848713          	addi	a4,s1,8
    80002ba4:	02e7e663          	bltu	a5,a4,80002bd0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ba8:	46a1                	li	a3,8
    80002baa:	8626                	mv	a2,s1
    80002bac:	85ca                	mv	a1,s2
    80002bae:	7128                	ld	a0,96(a0)
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	b60080e7          	jalr	-1184(ra) # 80001710 <copyin>
    80002bb8:	00a03533          	snez	a0,a0
    80002bbc:	40a00533          	neg	a0,a0
}
    80002bc0:	60e2                	ld	ra,24(sp)
    80002bc2:	6442                	ld	s0,16(sp)
    80002bc4:	64a2                	ld	s1,8(sp)
    80002bc6:	6902                	ld	s2,0(sp)
    80002bc8:	6105                	addi	sp,sp,32
    80002bca:	8082                	ret
    return -1;
    80002bcc:	557d                	li	a0,-1
    80002bce:	bfcd                	j	80002bc0 <fetchaddr+0x3e>
    80002bd0:	557d                	li	a0,-1
    80002bd2:	b7fd                	j	80002bc0 <fetchaddr+0x3e>

0000000080002bd4 <fetchstr>:
{
    80002bd4:	7179                	addi	sp,sp,-48
    80002bd6:	f406                	sd	ra,40(sp)
    80002bd8:	f022                	sd	s0,32(sp)
    80002bda:	ec26                	sd	s1,24(sp)
    80002bdc:	e84a                	sd	s2,16(sp)
    80002bde:	e44e                	sd	s3,8(sp)
    80002be0:	1800                	addi	s0,sp,48
    80002be2:	892a                	mv	s2,a0
    80002be4:	84ae                	mv	s1,a1
    80002be6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	dde080e7          	jalr	-546(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002bf0:	86ce                	mv	a3,s3
    80002bf2:	864a                	mv	a2,s2
    80002bf4:	85a6                	mv	a1,s1
    80002bf6:	7128                	ld	a0,96(a0)
    80002bf8:	fffff097          	auipc	ra,0xfffff
    80002bfc:	ba4080e7          	jalr	-1116(ra) # 8000179c <copyinstr>
    80002c00:	00054e63          	bltz	a0,80002c1c <fetchstr+0x48>
  return strlen(buf);
    80002c04:	8526                	mv	a0,s1
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	264080e7          	jalr	612(ra) # 80000e6a <strlen>
}
    80002c0e:	70a2                	ld	ra,40(sp)
    80002c10:	7402                	ld	s0,32(sp)
    80002c12:	64e2                	ld	s1,24(sp)
    80002c14:	6942                	ld	s2,16(sp)
    80002c16:	69a2                	ld	s3,8(sp)
    80002c18:	6145                	addi	sp,sp,48
    80002c1a:	8082                	ret
    return -1;
    80002c1c:	557d                	li	a0,-1
    80002c1e:	bfc5                	j	80002c0e <fetchstr+0x3a>

0000000080002c20 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c20:	1101                	addi	sp,sp,-32
    80002c22:	ec06                	sd	ra,24(sp)
    80002c24:	e822                	sd	s0,16(sp)
    80002c26:	e426                	sd	s1,8(sp)
    80002c28:	1000                	addi	s0,sp,32
    80002c2a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	eee080e7          	jalr	-274(ra) # 80002b1a <argraw>
    80002c34:	c088                	sw	a0,0(s1)
}
    80002c36:	60e2                	ld	ra,24(sp)
    80002c38:	6442                	ld	s0,16(sp)
    80002c3a:	64a2                	ld	s1,8(sp)
    80002c3c:	6105                	addi	sp,sp,32
    80002c3e:	8082                	ret

0000000080002c40 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c40:	1101                	addi	sp,sp,-32
    80002c42:	ec06                	sd	ra,24(sp)
    80002c44:	e822                	sd	s0,16(sp)
    80002c46:	e426                	sd	s1,8(sp)
    80002c48:	1000                	addi	s0,sp,32
    80002c4a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	ece080e7          	jalr	-306(ra) # 80002b1a <argraw>
    80002c54:	e088                	sd	a0,0(s1)
}
    80002c56:	60e2                	ld	ra,24(sp)
    80002c58:	6442                	ld	s0,16(sp)
    80002c5a:	64a2                	ld	s1,8(sp)
    80002c5c:	6105                	addi	sp,sp,32
    80002c5e:	8082                	ret

0000000080002c60 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c60:	7179                	addi	sp,sp,-48
    80002c62:	f406                	sd	ra,40(sp)
    80002c64:	f022                	sd	s0,32(sp)
    80002c66:	ec26                	sd	s1,24(sp)
    80002c68:	e84a                	sd	s2,16(sp)
    80002c6a:	1800                	addi	s0,sp,48
    80002c6c:	84ae                	mv	s1,a1
    80002c6e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c70:	fd840593          	addi	a1,s0,-40
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	fcc080e7          	jalr	-52(ra) # 80002c40 <argaddr>
  return fetchstr(addr, buf, max);
    80002c7c:	864a                	mv	a2,s2
    80002c7e:	85a6                	mv	a1,s1
    80002c80:	fd843503          	ld	a0,-40(s0)
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	f50080e7          	jalr	-176(ra) # 80002bd4 <fetchstr>
}
    80002c8c:	70a2                	ld	ra,40(sp)
    80002c8e:	7402                	ld	s0,32(sp)
    80002c90:	64e2                	ld	s1,24(sp)
    80002c92:	6942                	ld	s2,16(sp)
    80002c94:	6145                	addi	sp,sp,48
    80002c96:	8082                	ret

0000000080002c98 <syscall>:
[SYS_sched_tickets] sys_sched_tickets,
};

void
syscall(void)
{
    80002c98:	1101                	addi	sp,sp,-32
    80002c9a:	ec06                	sd	ra,24(sp)
    80002c9c:	e822                	sd	s0,16(sp)
    80002c9e:	e426                	sd	s1,8(sp)
    80002ca0:	e04a                	sd	s2,0(sp)
    80002ca2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ca4:	fffff097          	auipc	ra,0xfffff
    80002ca8:	d22080e7          	jalr	-734(ra) # 800019c6 <myproc>
    80002cac:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cae:	06853903          	ld	s2,104(a0)
    80002cb2:	0a893783          	ld	a5,168(s2)
    80002cb6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cba:	37fd                	addiw	a5,a5,-1
    80002cbc:	4759                	li	a4,22
    80002cbe:	00f76f63          	bltu	a4,a5,80002cdc <syscall+0x44>
    80002cc2:	00369713          	slli	a4,a3,0x3
    80002cc6:	00005797          	auipc	a5,0x5
    80002cca:	7e278793          	addi	a5,a5,2018 # 800084a8 <syscalls>
    80002cce:	97ba                	add	a5,a5,a4
    80002cd0:	639c                	ld	a5,0(a5)
    80002cd2:	c789                	beqz	a5,80002cdc <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002cd4:	9782                	jalr	a5
    80002cd6:	06a93823          	sd	a0,112(s2)
    80002cda:	a839                	j	80002cf8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cdc:	16848613          	addi	a2,s1,360
    80002ce0:	588c                	lw	a1,48(s1)
    80002ce2:	00005517          	auipc	a0,0x5
    80002ce6:	78e50513          	addi	a0,a0,1934 # 80008470 <states.1733+0x150>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	8a4080e7          	jalr	-1884(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cf2:	74bc                	ld	a5,104(s1)
    80002cf4:	577d                	li	a4,-1
    80002cf6:	fbb8                	sd	a4,112(a5)
  }
}
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	64a2                	ld	s1,8(sp)
    80002cfe:	6902                	ld	s2,0(sp)
    80002d00:	6105                	addi	sp,sp,32
    80002d02:	8082                	ret

0000000080002d04 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d04:	1101                	addi	sp,sp,-32
    80002d06:	ec06                	sd	ra,24(sp)
    80002d08:	e822                	sd	s0,16(sp)
    80002d0a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d0c:	fec40593          	addi	a1,s0,-20
    80002d10:	4501                	li	a0,0
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	f0e080e7          	jalr	-242(ra) # 80002c20 <argint>
  exit(n);
    80002d1a:	fec42503          	lw	a0,-20(s0)
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	4f8080e7          	jalr	1272(ra) # 80002216 <exit>
  return 0;  // not reached
}
    80002d26:	4501                	li	a0,0
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	6105                	addi	sp,sp,32
    80002d2e:	8082                	ret

0000000080002d30 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d30:	1141                	addi	sp,sp,-16
    80002d32:	e406                	sd	ra,8(sp)
    80002d34:	e022                	sd	s0,0(sp)
    80002d36:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	c8e080e7          	jalr	-882(ra) # 800019c6 <myproc>
}
    80002d40:	5908                	lw	a0,48(a0)
    80002d42:	60a2                	ld	ra,8(sp)
    80002d44:	6402                	ld	s0,0(sp)
    80002d46:	0141                	addi	sp,sp,16
    80002d48:	8082                	ret

0000000080002d4a <sys_fork>:

uint64
sys_fork(void)
{
    80002d4a:	1141                	addi	sp,sp,-16
    80002d4c:	e406                	sd	ra,8(sp)
    80002d4e:	e022                	sd	s0,0(sp)
    80002d50:	0800                	addi	s0,sp,16
  return fork();
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	03e080e7          	jalr	62(ra) # 80001d90 <fork>
}
    80002d5a:	60a2                	ld	ra,8(sp)
    80002d5c:	6402                	ld	s0,0(sp)
    80002d5e:	0141                	addi	sp,sp,16
    80002d60:	8082                	ret

0000000080002d62 <sys_wait>:

uint64
sys_wait(void)
{
    80002d62:	1101                	addi	sp,sp,-32
    80002d64:	ec06                	sd	ra,24(sp)
    80002d66:	e822                	sd	s0,16(sp)
    80002d68:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d6a:	fe840593          	addi	a1,s0,-24
    80002d6e:	4501                	li	a0,0
    80002d70:	00000097          	auipc	ra,0x0
    80002d74:	ed0080e7          	jalr	-304(ra) # 80002c40 <argaddr>
  return wait(p);
    80002d78:	fe843503          	ld	a0,-24(s0)
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	640080e7          	jalr	1600(ra) # 800023bc <wait>
}
    80002d84:	60e2                	ld	ra,24(sp)
    80002d86:	6442                	ld	s0,16(sp)
    80002d88:	6105                	addi	sp,sp,32
    80002d8a:	8082                	ret

0000000080002d8c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d8c:	7179                	addi	sp,sp,-48
    80002d8e:	f406                	sd	ra,40(sp)
    80002d90:	f022                	sd	s0,32(sp)
    80002d92:	ec26                	sd	s1,24(sp)
    80002d94:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d96:	fdc40593          	addi	a1,s0,-36
    80002d9a:	4501                	li	a0,0
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	e84080e7          	jalr	-380(ra) # 80002c20 <argint>
  addr = myproc()->sz;
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	c22080e7          	jalr	-990(ra) # 800019c6 <myproc>
    80002dac:	6d24                	ld	s1,88(a0)
  if(growproc(n) < 0)
    80002dae:	fdc42503          	lw	a0,-36(s0)
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	f82080e7          	jalr	-126(ra) # 80001d34 <growproc>
    80002dba:	00054863          	bltz	a0,80002dca <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002dbe:	8526                	mv	a0,s1
    80002dc0:	70a2                	ld	ra,40(sp)
    80002dc2:	7402                	ld	s0,32(sp)
    80002dc4:	64e2                	ld	s1,24(sp)
    80002dc6:	6145                	addi	sp,sp,48
    80002dc8:	8082                	ret
    return -1;
    80002dca:	54fd                	li	s1,-1
    80002dcc:	bfcd                	j	80002dbe <sys_sbrk+0x32>

0000000080002dce <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dce:	7139                	addi	sp,sp,-64
    80002dd0:	fc06                	sd	ra,56(sp)
    80002dd2:	f822                	sd	s0,48(sp)
    80002dd4:	f426                	sd	s1,40(sp)
    80002dd6:	f04a                	sd	s2,32(sp)
    80002dd8:	ec4e                	sd	s3,24(sp)
    80002dda:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ddc:	fcc40593          	addi	a1,s0,-52
    80002de0:	4501                	li	a0,0
    80002de2:	00000097          	auipc	ra,0x0
    80002de6:	e3e080e7          	jalr	-450(ra) # 80002c20 <argint>
  acquire(&tickslock);
    80002dea:	00014517          	auipc	a0,0x14
    80002dee:	00650513          	addi	a0,a0,6 # 80016df0 <tickslock>
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	df8080e7          	jalr	-520(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002dfa:	00006917          	auipc	s2,0x6
    80002dfe:	b5692903          	lw	s2,-1194(s2) # 80008950 <ticks>
  while(ticks - ticks0 < n){
    80002e02:	fcc42783          	lw	a5,-52(s0)
    80002e06:	cf9d                	beqz	a5,80002e44 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e08:	00014997          	auipc	s3,0x14
    80002e0c:	fe898993          	addi	s3,s3,-24 # 80016df0 <tickslock>
    80002e10:	00006497          	auipc	s1,0x6
    80002e14:	b4048493          	addi	s1,s1,-1216 # 80008950 <ticks>
    if(killed(myproc())){
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	bae080e7          	jalr	-1106(ra) # 800019c6 <myproc>
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	56a080e7          	jalr	1386(ra) # 8000238a <killed>
    80002e28:	ed15                	bnez	a0,80002e64 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e2a:	85ce                	mv	a1,s3
    80002e2c:	8526                	mv	a0,s1
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	2b4080e7          	jalr	692(ra) # 800020e2 <sleep>
  while(ticks - ticks0 < n){
    80002e36:	409c                	lw	a5,0(s1)
    80002e38:	412787bb          	subw	a5,a5,s2
    80002e3c:	fcc42703          	lw	a4,-52(s0)
    80002e40:	fce7ece3          	bltu	a5,a4,80002e18 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e44:	00014517          	auipc	a0,0x14
    80002e48:	fac50513          	addi	a0,a0,-84 # 80016df0 <tickslock>
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	e52080e7          	jalr	-430(ra) # 80000c9e <release>
  return 0;
    80002e54:	4501                	li	a0,0
}
    80002e56:	70e2                	ld	ra,56(sp)
    80002e58:	7442                	ld	s0,48(sp)
    80002e5a:	74a2                	ld	s1,40(sp)
    80002e5c:	7902                	ld	s2,32(sp)
    80002e5e:	69e2                	ld	s3,24(sp)
    80002e60:	6121                	addi	sp,sp,64
    80002e62:	8082                	ret
      release(&tickslock);
    80002e64:	00014517          	auipc	a0,0x14
    80002e68:	f8c50513          	addi	a0,a0,-116 # 80016df0 <tickslock>
    80002e6c:	ffffe097          	auipc	ra,0xffffe
    80002e70:	e32080e7          	jalr	-462(ra) # 80000c9e <release>
      return -1;
    80002e74:	557d                	li	a0,-1
    80002e76:	b7c5                	j	80002e56 <sys_sleep+0x88>

0000000080002e78 <sys_kill>:

uint64
sys_kill(void)
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e80:	fec40593          	addi	a1,s0,-20
    80002e84:	4501                	li	a0,0
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	d9a080e7          	jalr	-614(ra) # 80002c20 <argint>
  return kill(pid);
    80002e8e:	fec42503          	lw	a0,-20(s0)
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	45a080e7          	jalr	1114(ra) # 800022ec <kill>
}
    80002e9a:	60e2                	ld	ra,24(sp)
    80002e9c:	6442                	ld	s0,16(sp)
    80002e9e:	6105                	addi	sp,sp,32
    80002ea0:	8082                	ret

0000000080002ea2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ea2:	1101                	addi	sp,sp,-32
    80002ea4:	ec06                	sd	ra,24(sp)
    80002ea6:	e822                	sd	s0,16(sp)
    80002ea8:	e426                	sd	s1,8(sp)
    80002eaa:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eac:	00014517          	auipc	a0,0x14
    80002eb0:	f4450513          	addi	a0,a0,-188 # 80016df0 <tickslock>
    80002eb4:	ffffe097          	auipc	ra,0xffffe
    80002eb8:	d36080e7          	jalr	-714(ra) # 80000bea <acquire>
  xticks = ticks;
    80002ebc:	00006497          	auipc	s1,0x6
    80002ec0:	a944a483          	lw	s1,-1388(s1) # 80008950 <ticks>
  release(&tickslock);
    80002ec4:	00014517          	auipc	a0,0x14
    80002ec8:	f2c50513          	addi	a0,a0,-212 # 80016df0 <tickslock>
    80002ecc:	ffffe097          	auipc	ra,0xffffe
    80002ed0:	dd2080e7          	jalr	-558(ra) # 80000c9e <release>
  return xticks;
}
    80002ed4:	02049513          	slli	a0,s1,0x20
    80002ed8:	9101                	srli	a0,a0,0x20
    80002eda:	60e2                	ld	ra,24(sp)
    80002edc:	6442                	ld	s0,16(sp)
    80002ede:	64a2                	ld	s1,8(sp)
    80002ee0:	6105                	addi	sp,sp,32
    80002ee2:	8082                	ret

0000000080002ee4 <sys_sched_statistics>:

uint64
sys_sched_statistics(void)
{
    80002ee4:	1141                	addi	sp,sp,-16
    80002ee6:	e406                	sd	ra,8(sp)
    80002ee8:	e022                	sd	s0,0(sp)
    80002eea:	0800                	addi	s0,sp,16
  return sched_statistics();
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	758080e7          	jalr	1880(ra) # 80002644 <sched_statistics>
}
    80002ef4:	60a2                	ld	ra,8(sp)
    80002ef6:	6402                	ld	s0,0(sp)
    80002ef8:	0141                	addi	sp,sp,16
    80002efa:	8082                	ret

0000000080002efc <sys_sched_tickets>:

uint64
sys_sched_tickets(void)
{
    80002efc:	1101                	addi	sp,sp,-32
    80002efe:	ec06                	sd	ra,24(sp)
    80002f00:	e822                	sd	s0,16(sp)
    80002f02:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002f04:	fec40593          	addi	a1,s0,-20
    80002f08:	4501                	li	a0,0
    80002f0a:	00000097          	auipc	ra,0x0
    80002f0e:	d16080e7          	jalr	-746(ra) # 80002c20 <argint>
  return sched_tickets(n);
    80002f12:	fec42503          	lw	a0,-20(s0)
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	788080e7          	jalr	1928(ra) # 8000269e <sched_tickets>
}
    80002f1e:	60e2                	ld	ra,24(sp)
    80002f20:	6442                	ld	s0,16(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret

0000000080002f26 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f26:	7179                	addi	sp,sp,-48
    80002f28:	f406                	sd	ra,40(sp)
    80002f2a:	f022                	sd	s0,32(sp)
    80002f2c:	ec26                	sd	s1,24(sp)
    80002f2e:	e84a                	sd	s2,16(sp)
    80002f30:	e44e                	sd	s3,8(sp)
    80002f32:	e052                	sd	s4,0(sp)
    80002f34:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f36:	00005597          	auipc	a1,0x5
    80002f3a:	63258593          	addi	a1,a1,1586 # 80008568 <syscalls+0xc0>
    80002f3e:	00014517          	auipc	a0,0x14
    80002f42:	eca50513          	addi	a0,a0,-310 # 80016e08 <bcache>
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	c14080e7          	jalr	-1004(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f4e:	0001c797          	auipc	a5,0x1c
    80002f52:	eba78793          	addi	a5,a5,-326 # 8001ee08 <bcache+0x8000>
    80002f56:	0001c717          	auipc	a4,0x1c
    80002f5a:	11a70713          	addi	a4,a4,282 # 8001f070 <bcache+0x8268>
    80002f5e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f62:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f66:	00014497          	auipc	s1,0x14
    80002f6a:	eba48493          	addi	s1,s1,-326 # 80016e20 <bcache+0x18>
    b->next = bcache.head.next;
    80002f6e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f70:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f72:	00005a17          	auipc	s4,0x5
    80002f76:	5fea0a13          	addi	s4,s4,1534 # 80008570 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f7a:	2b893783          	ld	a5,696(s2)
    80002f7e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f80:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f84:	85d2                	mv	a1,s4
    80002f86:	01048513          	addi	a0,s1,16
    80002f8a:	00001097          	auipc	ra,0x1
    80002f8e:	4c4080e7          	jalr	1220(ra) # 8000444e <initsleeplock>
    bcache.head.next->prev = b;
    80002f92:	2b893783          	ld	a5,696(s2)
    80002f96:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f98:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f9c:	45848493          	addi	s1,s1,1112
    80002fa0:	fd349de3          	bne	s1,s3,80002f7a <binit+0x54>
  }
}
    80002fa4:	70a2                	ld	ra,40(sp)
    80002fa6:	7402                	ld	s0,32(sp)
    80002fa8:	64e2                	ld	s1,24(sp)
    80002faa:	6942                	ld	s2,16(sp)
    80002fac:	69a2                	ld	s3,8(sp)
    80002fae:	6a02                	ld	s4,0(sp)
    80002fb0:	6145                	addi	sp,sp,48
    80002fb2:	8082                	ret

0000000080002fb4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fb4:	7179                	addi	sp,sp,-48
    80002fb6:	f406                	sd	ra,40(sp)
    80002fb8:	f022                	sd	s0,32(sp)
    80002fba:	ec26                	sd	s1,24(sp)
    80002fbc:	e84a                	sd	s2,16(sp)
    80002fbe:	e44e                	sd	s3,8(sp)
    80002fc0:	1800                	addi	s0,sp,48
    80002fc2:	89aa                	mv	s3,a0
    80002fc4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fc6:	00014517          	auipc	a0,0x14
    80002fca:	e4250513          	addi	a0,a0,-446 # 80016e08 <bcache>
    80002fce:	ffffe097          	auipc	ra,0xffffe
    80002fd2:	c1c080e7          	jalr	-996(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fd6:	0001c497          	auipc	s1,0x1c
    80002fda:	0ea4b483          	ld	s1,234(s1) # 8001f0c0 <bcache+0x82b8>
    80002fde:	0001c797          	auipc	a5,0x1c
    80002fe2:	09278793          	addi	a5,a5,146 # 8001f070 <bcache+0x8268>
    80002fe6:	02f48f63          	beq	s1,a5,80003024 <bread+0x70>
    80002fea:	873e                	mv	a4,a5
    80002fec:	a021                	j	80002ff4 <bread+0x40>
    80002fee:	68a4                	ld	s1,80(s1)
    80002ff0:	02e48a63          	beq	s1,a4,80003024 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ff4:	449c                	lw	a5,8(s1)
    80002ff6:	ff379ce3          	bne	a5,s3,80002fee <bread+0x3a>
    80002ffa:	44dc                	lw	a5,12(s1)
    80002ffc:	ff2799e3          	bne	a5,s2,80002fee <bread+0x3a>
      b->refcnt++;
    80003000:	40bc                	lw	a5,64(s1)
    80003002:	2785                	addiw	a5,a5,1
    80003004:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003006:	00014517          	auipc	a0,0x14
    8000300a:	e0250513          	addi	a0,a0,-510 # 80016e08 <bcache>
    8000300e:	ffffe097          	auipc	ra,0xffffe
    80003012:	c90080e7          	jalr	-880(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003016:	01048513          	addi	a0,s1,16
    8000301a:	00001097          	auipc	ra,0x1
    8000301e:	46e080e7          	jalr	1134(ra) # 80004488 <acquiresleep>
      return b;
    80003022:	a8b9                	j	80003080 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003024:	0001c497          	auipc	s1,0x1c
    80003028:	0944b483          	ld	s1,148(s1) # 8001f0b8 <bcache+0x82b0>
    8000302c:	0001c797          	auipc	a5,0x1c
    80003030:	04478793          	addi	a5,a5,68 # 8001f070 <bcache+0x8268>
    80003034:	00f48863          	beq	s1,a5,80003044 <bread+0x90>
    80003038:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000303a:	40bc                	lw	a5,64(s1)
    8000303c:	cf81                	beqz	a5,80003054 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000303e:	64a4                	ld	s1,72(s1)
    80003040:	fee49de3          	bne	s1,a4,8000303a <bread+0x86>
  panic("bget: no buffers");
    80003044:	00005517          	auipc	a0,0x5
    80003048:	53450513          	addi	a0,a0,1332 # 80008578 <syscalls+0xd0>
    8000304c:	ffffd097          	auipc	ra,0xffffd
    80003050:	4f8080e7          	jalr	1272(ra) # 80000544 <panic>
      b->dev = dev;
    80003054:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003058:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000305c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003060:	4785                	li	a5,1
    80003062:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003064:	00014517          	auipc	a0,0x14
    80003068:	da450513          	addi	a0,a0,-604 # 80016e08 <bcache>
    8000306c:	ffffe097          	auipc	ra,0xffffe
    80003070:	c32080e7          	jalr	-974(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003074:	01048513          	addi	a0,s1,16
    80003078:	00001097          	auipc	ra,0x1
    8000307c:	410080e7          	jalr	1040(ra) # 80004488 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003080:	409c                	lw	a5,0(s1)
    80003082:	cb89                	beqz	a5,80003094 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003084:	8526                	mv	a0,s1
    80003086:	70a2                	ld	ra,40(sp)
    80003088:	7402                	ld	s0,32(sp)
    8000308a:	64e2                	ld	s1,24(sp)
    8000308c:	6942                	ld	s2,16(sp)
    8000308e:	69a2                	ld	s3,8(sp)
    80003090:	6145                	addi	sp,sp,48
    80003092:	8082                	ret
    virtio_disk_rw(b, 0);
    80003094:	4581                	li	a1,0
    80003096:	8526                	mv	a0,s1
    80003098:	00003097          	auipc	ra,0x3
    8000309c:	fd0080e7          	jalr	-48(ra) # 80006068 <virtio_disk_rw>
    b->valid = 1;
    800030a0:	4785                	li	a5,1
    800030a2:	c09c                	sw	a5,0(s1)
  return b;
    800030a4:	b7c5                	j	80003084 <bread+0xd0>

00000000800030a6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030a6:	1101                	addi	sp,sp,-32
    800030a8:	ec06                	sd	ra,24(sp)
    800030aa:	e822                	sd	s0,16(sp)
    800030ac:	e426                	sd	s1,8(sp)
    800030ae:	1000                	addi	s0,sp,32
    800030b0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b2:	0541                	addi	a0,a0,16
    800030b4:	00001097          	auipc	ra,0x1
    800030b8:	46e080e7          	jalr	1134(ra) # 80004522 <holdingsleep>
    800030bc:	cd01                	beqz	a0,800030d4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030be:	4585                	li	a1,1
    800030c0:	8526                	mv	a0,s1
    800030c2:	00003097          	auipc	ra,0x3
    800030c6:	fa6080e7          	jalr	-90(ra) # 80006068 <virtio_disk_rw>
}
    800030ca:	60e2                	ld	ra,24(sp)
    800030cc:	6442                	ld	s0,16(sp)
    800030ce:	64a2                	ld	s1,8(sp)
    800030d0:	6105                	addi	sp,sp,32
    800030d2:	8082                	ret
    panic("bwrite");
    800030d4:	00005517          	auipc	a0,0x5
    800030d8:	4bc50513          	addi	a0,a0,1212 # 80008590 <syscalls+0xe8>
    800030dc:	ffffd097          	auipc	ra,0xffffd
    800030e0:	468080e7          	jalr	1128(ra) # 80000544 <panic>

00000000800030e4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030e4:	1101                	addi	sp,sp,-32
    800030e6:	ec06                	sd	ra,24(sp)
    800030e8:	e822                	sd	s0,16(sp)
    800030ea:	e426                	sd	s1,8(sp)
    800030ec:	e04a                	sd	s2,0(sp)
    800030ee:	1000                	addi	s0,sp,32
    800030f0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030f2:	01050913          	addi	s2,a0,16
    800030f6:	854a                	mv	a0,s2
    800030f8:	00001097          	auipc	ra,0x1
    800030fc:	42a080e7          	jalr	1066(ra) # 80004522 <holdingsleep>
    80003100:	c92d                	beqz	a0,80003172 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003102:	854a                	mv	a0,s2
    80003104:	00001097          	auipc	ra,0x1
    80003108:	3da080e7          	jalr	986(ra) # 800044de <releasesleep>

  acquire(&bcache.lock);
    8000310c:	00014517          	auipc	a0,0x14
    80003110:	cfc50513          	addi	a0,a0,-772 # 80016e08 <bcache>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	ad6080e7          	jalr	-1322(ra) # 80000bea <acquire>
  b->refcnt--;
    8000311c:	40bc                	lw	a5,64(s1)
    8000311e:	37fd                	addiw	a5,a5,-1
    80003120:	0007871b          	sext.w	a4,a5
    80003124:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003126:	eb05                	bnez	a4,80003156 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003128:	68bc                	ld	a5,80(s1)
    8000312a:	64b8                	ld	a4,72(s1)
    8000312c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000312e:	64bc                	ld	a5,72(s1)
    80003130:	68b8                	ld	a4,80(s1)
    80003132:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003134:	0001c797          	auipc	a5,0x1c
    80003138:	cd478793          	addi	a5,a5,-812 # 8001ee08 <bcache+0x8000>
    8000313c:	2b87b703          	ld	a4,696(a5)
    80003140:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003142:	0001c717          	auipc	a4,0x1c
    80003146:	f2e70713          	addi	a4,a4,-210 # 8001f070 <bcache+0x8268>
    8000314a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000314c:	2b87b703          	ld	a4,696(a5)
    80003150:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003152:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003156:	00014517          	auipc	a0,0x14
    8000315a:	cb250513          	addi	a0,a0,-846 # 80016e08 <bcache>
    8000315e:	ffffe097          	auipc	ra,0xffffe
    80003162:	b40080e7          	jalr	-1216(ra) # 80000c9e <release>
}
    80003166:	60e2                	ld	ra,24(sp)
    80003168:	6442                	ld	s0,16(sp)
    8000316a:	64a2                	ld	s1,8(sp)
    8000316c:	6902                	ld	s2,0(sp)
    8000316e:	6105                	addi	sp,sp,32
    80003170:	8082                	ret
    panic("brelse");
    80003172:	00005517          	auipc	a0,0x5
    80003176:	42650513          	addi	a0,a0,1062 # 80008598 <syscalls+0xf0>
    8000317a:	ffffd097          	auipc	ra,0xffffd
    8000317e:	3ca080e7          	jalr	970(ra) # 80000544 <panic>

0000000080003182 <bpin>:

void
bpin(struct buf *b) {
    80003182:	1101                	addi	sp,sp,-32
    80003184:	ec06                	sd	ra,24(sp)
    80003186:	e822                	sd	s0,16(sp)
    80003188:	e426                	sd	s1,8(sp)
    8000318a:	1000                	addi	s0,sp,32
    8000318c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000318e:	00014517          	auipc	a0,0x14
    80003192:	c7a50513          	addi	a0,a0,-902 # 80016e08 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	a54080e7          	jalr	-1452(ra) # 80000bea <acquire>
  b->refcnt++;
    8000319e:	40bc                	lw	a5,64(s1)
    800031a0:	2785                	addiw	a5,a5,1
    800031a2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a4:	00014517          	auipc	a0,0x14
    800031a8:	c6450513          	addi	a0,a0,-924 # 80016e08 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	af2080e7          	jalr	-1294(ra) # 80000c9e <release>
}
    800031b4:	60e2                	ld	ra,24(sp)
    800031b6:	6442                	ld	s0,16(sp)
    800031b8:	64a2                	ld	s1,8(sp)
    800031ba:	6105                	addi	sp,sp,32
    800031bc:	8082                	ret

00000000800031be <bunpin>:

void
bunpin(struct buf *b) {
    800031be:	1101                	addi	sp,sp,-32
    800031c0:	ec06                	sd	ra,24(sp)
    800031c2:	e822                	sd	s0,16(sp)
    800031c4:	e426                	sd	s1,8(sp)
    800031c6:	1000                	addi	s0,sp,32
    800031c8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ca:	00014517          	auipc	a0,0x14
    800031ce:	c3e50513          	addi	a0,a0,-962 # 80016e08 <bcache>
    800031d2:	ffffe097          	auipc	ra,0xffffe
    800031d6:	a18080e7          	jalr	-1512(ra) # 80000bea <acquire>
  b->refcnt--;
    800031da:	40bc                	lw	a5,64(s1)
    800031dc:	37fd                	addiw	a5,a5,-1
    800031de:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031e0:	00014517          	auipc	a0,0x14
    800031e4:	c2850513          	addi	a0,a0,-984 # 80016e08 <bcache>
    800031e8:	ffffe097          	auipc	ra,0xffffe
    800031ec:	ab6080e7          	jalr	-1354(ra) # 80000c9e <release>
}
    800031f0:	60e2                	ld	ra,24(sp)
    800031f2:	6442                	ld	s0,16(sp)
    800031f4:	64a2                	ld	s1,8(sp)
    800031f6:	6105                	addi	sp,sp,32
    800031f8:	8082                	ret

00000000800031fa <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031fa:	1101                	addi	sp,sp,-32
    800031fc:	ec06                	sd	ra,24(sp)
    800031fe:	e822                	sd	s0,16(sp)
    80003200:	e426                	sd	s1,8(sp)
    80003202:	e04a                	sd	s2,0(sp)
    80003204:	1000                	addi	s0,sp,32
    80003206:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003208:	00d5d59b          	srliw	a1,a1,0xd
    8000320c:	0001c797          	auipc	a5,0x1c
    80003210:	2d87a783          	lw	a5,728(a5) # 8001f4e4 <sb+0x1c>
    80003214:	9dbd                	addw	a1,a1,a5
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	d9e080e7          	jalr	-610(ra) # 80002fb4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000321e:	0074f713          	andi	a4,s1,7
    80003222:	4785                	li	a5,1
    80003224:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003228:	14ce                	slli	s1,s1,0x33
    8000322a:	90d9                	srli	s1,s1,0x36
    8000322c:	00950733          	add	a4,a0,s1
    80003230:	05874703          	lbu	a4,88(a4)
    80003234:	00e7f6b3          	and	a3,a5,a4
    80003238:	c69d                	beqz	a3,80003266 <bfree+0x6c>
    8000323a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000323c:	94aa                	add	s1,s1,a0
    8000323e:	fff7c793          	not	a5,a5
    80003242:	8ff9                	and	a5,a5,a4
    80003244:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003248:	00001097          	auipc	ra,0x1
    8000324c:	120080e7          	jalr	288(ra) # 80004368 <log_write>
  brelse(bp);
    80003250:	854a                	mv	a0,s2
    80003252:	00000097          	auipc	ra,0x0
    80003256:	e92080e7          	jalr	-366(ra) # 800030e4 <brelse>
}
    8000325a:	60e2                	ld	ra,24(sp)
    8000325c:	6442                	ld	s0,16(sp)
    8000325e:	64a2                	ld	s1,8(sp)
    80003260:	6902                	ld	s2,0(sp)
    80003262:	6105                	addi	sp,sp,32
    80003264:	8082                	ret
    panic("freeing free block");
    80003266:	00005517          	auipc	a0,0x5
    8000326a:	33a50513          	addi	a0,a0,826 # 800085a0 <syscalls+0xf8>
    8000326e:	ffffd097          	auipc	ra,0xffffd
    80003272:	2d6080e7          	jalr	726(ra) # 80000544 <panic>

0000000080003276 <balloc>:
{
    80003276:	711d                	addi	sp,sp,-96
    80003278:	ec86                	sd	ra,88(sp)
    8000327a:	e8a2                	sd	s0,80(sp)
    8000327c:	e4a6                	sd	s1,72(sp)
    8000327e:	e0ca                	sd	s2,64(sp)
    80003280:	fc4e                	sd	s3,56(sp)
    80003282:	f852                	sd	s4,48(sp)
    80003284:	f456                	sd	s5,40(sp)
    80003286:	f05a                	sd	s6,32(sp)
    80003288:	ec5e                	sd	s7,24(sp)
    8000328a:	e862                	sd	s8,16(sp)
    8000328c:	e466                	sd	s9,8(sp)
    8000328e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003290:	0001c797          	auipc	a5,0x1c
    80003294:	23c7a783          	lw	a5,572(a5) # 8001f4cc <sb+0x4>
    80003298:	10078163          	beqz	a5,8000339a <balloc+0x124>
    8000329c:	8baa                	mv	s7,a0
    8000329e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032a0:	0001cb17          	auipc	s6,0x1c
    800032a4:	228b0b13          	addi	s6,s6,552 # 8001f4c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032aa:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ac:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032ae:	6c89                	lui	s9,0x2
    800032b0:	a061                	j	80003338 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032b2:	974a                	add	a4,a4,s2
    800032b4:	8fd5                	or	a5,a5,a3
    800032b6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032ba:	854a                	mv	a0,s2
    800032bc:	00001097          	auipc	ra,0x1
    800032c0:	0ac080e7          	jalr	172(ra) # 80004368 <log_write>
        brelse(bp);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	e1e080e7          	jalr	-482(ra) # 800030e4 <brelse>
  bp = bread(dev, bno);
    800032ce:	85a6                	mv	a1,s1
    800032d0:	855e                	mv	a0,s7
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	ce2080e7          	jalr	-798(ra) # 80002fb4 <bread>
    800032da:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032dc:	40000613          	li	a2,1024
    800032e0:	4581                	li	a1,0
    800032e2:	05850513          	addi	a0,a0,88
    800032e6:	ffffe097          	auipc	ra,0xffffe
    800032ea:	a00080e7          	jalr	-1536(ra) # 80000ce6 <memset>
  log_write(bp);
    800032ee:	854a                	mv	a0,s2
    800032f0:	00001097          	auipc	ra,0x1
    800032f4:	078080e7          	jalr	120(ra) # 80004368 <log_write>
  brelse(bp);
    800032f8:	854a                	mv	a0,s2
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	dea080e7          	jalr	-534(ra) # 800030e4 <brelse>
}
    80003302:	8526                	mv	a0,s1
    80003304:	60e6                	ld	ra,88(sp)
    80003306:	6446                	ld	s0,80(sp)
    80003308:	64a6                	ld	s1,72(sp)
    8000330a:	6906                	ld	s2,64(sp)
    8000330c:	79e2                	ld	s3,56(sp)
    8000330e:	7a42                	ld	s4,48(sp)
    80003310:	7aa2                	ld	s5,40(sp)
    80003312:	7b02                	ld	s6,32(sp)
    80003314:	6be2                	ld	s7,24(sp)
    80003316:	6c42                	ld	s8,16(sp)
    80003318:	6ca2                	ld	s9,8(sp)
    8000331a:	6125                	addi	sp,sp,96
    8000331c:	8082                	ret
    brelse(bp);
    8000331e:	854a                	mv	a0,s2
    80003320:	00000097          	auipc	ra,0x0
    80003324:	dc4080e7          	jalr	-572(ra) # 800030e4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003328:	015c87bb          	addw	a5,s9,s5
    8000332c:	00078a9b          	sext.w	s5,a5
    80003330:	004b2703          	lw	a4,4(s6)
    80003334:	06eaf363          	bgeu	s5,a4,8000339a <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003338:	41fad79b          	sraiw	a5,s5,0x1f
    8000333c:	0137d79b          	srliw	a5,a5,0x13
    80003340:	015787bb          	addw	a5,a5,s5
    80003344:	40d7d79b          	sraiw	a5,a5,0xd
    80003348:	01cb2583          	lw	a1,28(s6)
    8000334c:	9dbd                	addw	a1,a1,a5
    8000334e:	855e                	mv	a0,s7
    80003350:	00000097          	auipc	ra,0x0
    80003354:	c64080e7          	jalr	-924(ra) # 80002fb4 <bread>
    80003358:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000335a:	004b2503          	lw	a0,4(s6)
    8000335e:	000a849b          	sext.w	s1,s5
    80003362:	8662                	mv	a2,s8
    80003364:	faa4fde3          	bgeu	s1,a0,8000331e <balloc+0xa8>
      m = 1 << (bi % 8);
    80003368:	41f6579b          	sraiw	a5,a2,0x1f
    8000336c:	01d7d69b          	srliw	a3,a5,0x1d
    80003370:	00c6873b          	addw	a4,a3,a2
    80003374:	00777793          	andi	a5,a4,7
    80003378:	9f95                	subw	a5,a5,a3
    8000337a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000337e:	4037571b          	sraiw	a4,a4,0x3
    80003382:	00e906b3          	add	a3,s2,a4
    80003386:	0586c683          	lbu	a3,88(a3)
    8000338a:	00d7f5b3          	and	a1,a5,a3
    8000338e:	d195                	beqz	a1,800032b2 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003390:	2605                	addiw	a2,a2,1
    80003392:	2485                	addiw	s1,s1,1
    80003394:	fd4618e3          	bne	a2,s4,80003364 <balloc+0xee>
    80003398:	b759                	j	8000331e <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000339a:	00005517          	auipc	a0,0x5
    8000339e:	21e50513          	addi	a0,a0,542 # 800085b8 <syscalls+0x110>
    800033a2:	ffffd097          	auipc	ra,0xffffd
    800033a6:	1ec080e7          	jalr	492(ra) # 8000058e <printf>
  return 0;
    800033aa:	4481                	li	s1,0
    800033ac:	bf99                	j	80003302 <balloc+0x8c>

00000000800033ae <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033ae:	7179                	addi	sp,sp,-48
    800033b0:	f406                	sd	ra,40(sp)
    800033b2:	f022                	sd	s0,32(sp)
    800033b4:	ec26                	sd	s1,24(sp)
    800033b6:	e84a                	sd	s2,16(sp)
    800033b8:	e44e                	sd	s3,8(sp)
    800033ba:	e052                	sd	s4,0(sp)
    800033bc:	1800                	addi	s0,sp,48
    800033be:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033c0:	47ad                	li	a5,11
    800033c2:	02b7e763          	bltu	a5,a1,800033f0 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033c6:	02059493          	slli	s1,a1,0x20
    800033ca:	9081                	srli	s1,s1,0x20
    800033cc:	048a                	slli	s1,s1,0x2
    800033ce:	94aa                	add	s1,s1,a0
    800033d0:	0504a903          	lw	s2,80(s1)
    800033d4:	06091e63          	bnez	s2,80003450 <bmap+0xa2>
      addr = balloc(ip->dev);
    800033d8:	4108                	lw	a0,0(a0)
    800033da:	00000097          	auipc	ra,0x0
    800033de:	e9c080e7          	jalr	-356(ra) # 80003276 <balloc>
    800033e2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033e6:	06090563          	beqz	s2,80003450 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033ea:	0524a823          	sw	s2,80(s1)
    800033ee:	a08d                	j	80003450 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033f0:	ff45849b          	addiw	s1,a1,-12
    800033f4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033f8:	0ff00793          	li	a5,255
    800033fc:	08e7e563          	bltu	a5,a4,80003486 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003400:	08052903          	lw	s2,128(a0)
    80003404:	00091d63          	bnez	s2,8000341e <bmap+0x70>
      addr = balloc(ip->dev);
    80003408:	4108                	lw	a0,0(a0)
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	e6c080e7          	jalr	-404(ra) # 80003276 <balloc>
    80003412:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003416:	02090d63          	beqz	s2,80003450 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000341a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000341e:	85ca                	mv	a1,s2
    80003420:	0009a503          	lw	a0,0(s3)
    80003424:	00000097          	auipc	ra,0x0
    80003428:	b90080e7          	jalr	-1136(ra) # 80002fb4 <bread>
    8000342c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000342e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003432:	02049593          	slli	a1,s1,0x20
    80003436:	9181                	srli	a1,a1,0x20
    80003438:	058a                	slli	a1,a1,0x2
    8000343a:	00b784b3          	add	s1,a5,a1
    8000343e:	0004a903          	lw	s2,0(s1)
    80003442:	02090063          	beqz	s2,80003462 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003446:	8552                	mv	a0,s4
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	c9c080e7          	jalr	-868(ra) # 800030e4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003450:	854a                	mv	a0,s2
    80003452:	70a2                	ld	ra,40(sp)
    80003454:	7402                	ld	s0,32(sp)
    80003456:	64e2                	ld	s1,24(sp)
    80003458:	6942                	ld	s2,16(sp)
    8000345a:	69a2                	ld	s3,8(sp)
    8000345c:	6a02                	ld	s4,0(sp)
    8000345e:	6145                	addi	sp,sp,48
    80003460:	8082                	ret
      addr = balloc(ip->dev);
    80003462:	0009a503          	lw	a0,0(s3)
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	e10080e7          	jalr	-496(ra) # 80003276 <balloc>
    8000346e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003472:	fc090ae3          	beqz	s2,80003446 <bmap+0x98>
        a[bn] = addr;
    80003476:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000347a:	8552                	mv	a0,s4
    8000347c:	00001097          	auipc	ra,0x1
    80003480:	eec080e7          	jalr	-276(ra) # 80004368 <log_write>
    80003484:	b7c9                	j	80003446 <bmap+0x98>
  panic("bmap: out of range");
    80003486:	00005517          	auipc	a0,0x5
    8000348a:	14a50513          	addi	a0,a0,330 # 800085d0 <syscalls+0x128>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	0b6080e7          	jalr	182(ra) # 80000544 <panic>

0000000080003496 <iget>:
{
    80003496:	7179                	addi	sp,sp,-48
    80003498:	f406                	sd	ra,40(sp)
    8000349a:	f022                	sd	s0,32(sp)
    8000349c:	ec26                	sd	s1,24(sp)
    8000349e:	e84a                	sd	s2,16(sp)
    800034a0:	e44e                	sd	s3,8(sp)
    800034a2:	e052                	sd	s4,0(sp)
    800034a4:	1800                	addi	s0,sp,48
    800034a6:	89aa                	mv	s3,a0
    800034a8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034aa:	0001c517          	auipc	a0,0x1c
    800034ae:	03e50513          	addi	a0,a0,62 # 8001f4e8 <itable>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	738080e7          	jalr	1848(ra) # 80000bea <acquire>
  empty = 0;
    800034ba:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034bc:	0001c497          	auipc	s1,0x1c
    800034c0:	04448493          	addi	s1,s1,68 # 8001f500 <itable+0x18>
    800034c4:	0001e697          	auipc	a3,0x1e
    800034c8:	acc68693          	addi	a3,a3,-1332 # 80020f90 <log>
    800034cc:	a039                	j	800034da <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ce:	02090b63          	beqz	s2,80003504 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034d2:	08848493          	addi	s1,s1,136
    800034d6:	02d48a63          	beq	s1,a3,8000350a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034da:	449c                	lw	a5,8(s1)
    800034dc:	fef059e3          	blez	a5,800034ce <iget+0x38>
    800034e0:	4098                	lw	a4,0(s1)
    800034e2:	ff3716e3          	bne	a4,s3,800034ce <iget+0x38>
    800034e6:	40d8                	lw	a4,4(s1)
    800034e8:	ff4713e3          	bne	a4,s4,800034ce <iget+0x38>
      ip->ref++;
    800034ec:	2785                	addiw	a5,a5,1
    800034ee:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034f0:	0001c517          	auipc	a0,0x1c
    800034f4:	ff850513          	addi	a0,a0,-8 # 8001f4e8 <itable>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	7a6080e7          	jalr	1958(ra) # 80000c9e <release>
      return ip;
    80003500:	8926                	mv	s2,s1
    80003502:	a03d                	j	80003530 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003504:	f7f9                	bnez	a5,800034d2 <iget+0x3c>
    80003506:	8926                	mv	s2,s1
    80003508:	b7e9                	j	800034d2 <iget+0x3c>
  if(empty == 0)
    8000350a:	02090c63          	beqz	s2,80003542 <iget+0xac>
  ip->dev = dev;
    8000350e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003512:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003516:	4785                	li	a5,1
    80003518:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000351c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003520:	0001c517          	auipc	a0,0x1c
    80003524:	fc850513          	addi	a0,a0,-56 # 8001f4e8 <itable>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	776080e7          	jalr	1910(ra) # 80000c9e <release>
}
    80003530:	854a                	mv	a0,s2
    80003532:	70a2                	ld	ra,40(sp)
    80003534:	7402                	ld	s0,32(sp)
    80003536:	64e2                	ld	s1,24(sp)
    80003538:	6942                	ld	s2,16(sp)
    8000353a:	69a2                	ld	s3,8(sp)
    8000353c:	6a02                	ld	s4,0(sp)
    8000353e:	6145                	addi	sp,sp,48
    80003540:	8082                	ret
    panic("iget: no inodes");
    80003542:	00005517          	auipc	a0,0x5
    80003546:	0a650513          	addi	a0,a0,166 # 800085e8 <syscalls+0x140>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	ffa080e7          	jalr	-6(ra) # 80000544 <panic>

0000000080003552 <fsinit>:
fsinit(int dev) {
    80003552:	7179                	addi	sp,sp,-48
    80003554:	f406                	sd	ra,40(sp)
    80003556:	f022                	sd	s0,32(sp)
    80003558:	ec26                	sd	s1,24(sp)
    8000355a:	e84a                	sd	s2,16(sp)
    8000355c:	e44e                	sd	s3,8(sp)
    8000355e:	1800                	addi	s0,sp,48
    80003560:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003562:	4585                	li	a1,1
    80003564:	00000097          	auipc	ra,0x0
    80003568:	a50080e7          	jalr	-1456(ra) # 80002fb4 <bread>
    8000356c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000356e:	0001c997          	auipc	s3,0x1c
    80003572:	f5a98993          	addi	s3,s3,-166 # 8001f4c8 <sb>
    80003576:	02000613          	li	a2,32
    8000357a:	05850593          	addi	a1,a0,88
    8000357e:	854e                	mv	a0,s3
    80003580:	ffffd097          	auipc	ra,0xffffd
    80003584:	7c6080e7          	jalr	1990(ra) # 80000d46 <memmove>
  brelse(bp);
    80003588:	8526                	mv	a0,s1
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	b5a080e7          	jalr	-1190(ra) # 800030e4 <brelse>
  if(sb.magic != FSMAGIC)
    80003592:	0009a703          	lw	a4,0(s3)
    80003596:	102037b7          	lui	a5,0x10203
    8000359a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000359e:	02f71263          	bne	a4,a5,800035c2 <fsinit+0x70>
  initlog(dev, &sb);
    800035a2:	0001c597          	auipc	a1,0x1c
    800035a6:	f2658593          	addi	a1,a1,-218 # 8001f4c8 <sb>
    800035aa:	854a                	mv	a0,s2
    800035ac:	00001097          	auipc	ra,0x1
    800035b0:	b40080e7          	jalr	-1216(ra) # 800040ec <initlog>
}
    800035b4:	70a2                	ld	ra,40(sp)
    800035b6:	7402                	ld	s0,32(sp)
    800035b8:	64e2                	ld	s1,24(sp)
    800035ba:	6942                	ld	s2,16(sp)
    800035bc:	69a2                	ld	s3,8(sp)
    800035be:	6145                	addi	sp,sp,48
    800035c0:	8082                	ret
    panic("invalid file system");
    800035c2:	00005517          	auipc	a0,0x5
    800035c6:	03650513          	addi	a0,a0,54 # 800085f8 <syscalls+0x150>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	f7a080e7          	jalr	-134(ra) # 80000544 <panic>

00000000800035d2 <iinit>:
{
    800035d2:	7179                	addi	sp,sp,-48
    800035d4:	f406                	sd	ra,40(sp)
    800035d6:	f022                	sd	s0,32(sp)
    800035d8:	ec26                	sd	s1,24(sp)
    800035da:	e84a                	sd	s2,16(sp)
    800035dc:	e44e                	sd	s3,8(sp)
    800035de:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035e0:	00005597          	auipc	a1,0x5
    800035e4:	03058593          	addi	a1,a1,48 # 80008610 <syscalls+0x168>
    800035e8:	0001c517          	auipc	a0,0x1c
    800035ec:	f0050513          	addi	a0,a0,-256 # 8001f4e8 <itable>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	56a080e7          	jalr	1386(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800035f8:	0001c497          	auipc	s1,0x1c
    800035fc:	f1848493          	addi	s1,s1,-232 # 8001f510 <itable+0x28>
    80003600:	0001e997          	auipc	s3,0x1e
    80003604:	9a098993          	addi	s3,s3,-1632 # 80020fa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003608:	00005917          	auipc	s2,0x5
    8000360c:	01090913          	addi	s2,s2,16 # 80008618 <syscalls+0x170>
    80003610:	85ca                	mv	a1,s2
    80003612:	8526                	mv	a0,s1
    80003614:	00001097          	auipc	ra,0x1
    80003618:	e3a080e7          	jalr	-454(ra) # 8000444e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000361c:	08848493          	addi	s1,s1,136
    80003620:	ff3498e3          	bne	s1,s3,80003610 <iinit+0x3e>
}
    80003624:	70a2                	ld	ra,40(sp)
    80003626:	7402                	ld	s0,32(sp)
    80003628:	64e2                	ld	s1,24(sp)
    8000362a:	6942                	ld	s2,16(sp)
    8000362c:	69a2                	ld	s3,8(sp)
    8000362e:	6145                	addi	sp,sp,48
    80003630:	8082                	ret

0000000080003632 <ialloc>:
{
    80003632:	715d                	addi	sp,sp,-80
    80003634:	e486                	sd	ra,72(sp)
    80003636:	e0a2                	sd	s0,64(sp)
    80003638:	fc26                	sd	s1,56(sp)
    8000363a:	f84a                	sd	s2,48(sp)
    8000363c:	f44e                	sd	s3,40(sp)
    8000363e:	f052                	sd	s4,32(sp)
    80003640:	ec56                	sd	s5,24(sp)
    80003642:	e85a                	sd	s6,16(sp)
    80003644:	e45e                	sd	s7,8(sp)
    80003646:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003648:	0001c717          	auipc	a4,0x1c
    8000364c:	e8c72703          	lw	a4,-372(a4) # 8001f4d4 <sb+0xc>
    80003650:	4785                	li	a5,1
    80003652:	04e7fa63          	bgeu	a5,a4,800036a6 <ialloc+0x74>
    80003656:	8aaa                	mv	s5,a0
    80003658:	8bae                	mv	s7,a1
    8000365a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000365c:	0001ca17          	auipc	s4,0x1c
    80003660:	e6ca0a13          	addi	s4,s4,-404 # 8001f4c8 <sb>
    80003664:	00048b1b          	sext.w	s6,s1
    80003668:	0044d593          	srli	a1,s1,0x4
    8000366c:	018a2783          	lw	a5,24(s4)
    80003670:	9dbd                	addw	a1,a1,a5
    80003672:	8556                	mv	a0,s5
    80003674:	00000097          	auipc	ra,0x0
    80003678:	940080e7          	jalr	-1728(ra) # 80002fb4 <bread>
    8000367c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000367e:	05850993          	addi	s3,a0,88
    80003682:	00f4f793          	andi	a5,s1,15
    80003686:	079a                	slli	a5,a5,0x6
    80003688:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000368a:	00099783          	lh	a5,0(s3)
    8000368e:	c3a1                	beqz	a5,800036ce <ialloc+0x9c>
    brelse(bp);
    80003690:	00000097          	auipc	ra,0x0
    80003694:	a54080e7          	jalr	-1452(ra) # 800030e4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003698:	0485                	addi	s1,s1,1
    8000369a:	00ca2703          	lw	a4,12(s4)
    8000369e:	0004879b          	sext.w	a5,s1
    800036a2:	fce7e1e3          	bltu	a5,a4,80003664 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800036a6:	00005517          	auipc	a0,0x5
    800036aa:	f7a50513          	addi	a0,a0,-134 # 80008620 <syscalls+0x178>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	ee0080e7          	jalr	-288(ra) # 8000058e <printf>
  return 0;
    800036b6:	4501                	li	a0,0
}
    800036b8:	60a6                	ld	ra,72(sp)
    800036ba:	6406                	ld	s0,64(sp)
    800036bc:	74e2                	ld	s1,56(sp)
    800036be:	7942                	ld	s2,48(sp)
    800036c0:	79a2                	ld	s3,40(sp)
    800036c2:	7a02                	ld	s4,32(sp)
    800036c4:	6ae2                	ld	s5,24(sp)
    800036c6:	6b42                	ld	s6,16(sp)
    800036c8:	6ba2                	ld	s7,8(sp)
    800036ca:	6161                	addi	sp,sp,80
    800036cc:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036ce:	04000613          	li	a2,64
    800036d2:	4581                	li	a1,0
    800036d4:	854e                	mv	a0,s3
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	610080e7          	jalr	1552(ra) # 80000ce6 <memset>
      dip->type = type;
    800036de:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036e2:	854a                	mv	a0,s2
    800036e4:	00001097          	auipc	ra,0x1
    800036e8:	c84080e7          	jalr	-892(ra) # 80004368 <log_write>
      brelse(bp);
    800036ec:	854a                	mv	a0,s2
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	9f6080e7          	jalr	-1546(ra) # 800030e4 <brelse>
      return iget(dev, inum);
    800036f6:	85da                	mv	a1,s6
    800036f8:	8556                	mv	a0,s5
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	d9c080e7          	jalr	-612(ra) # 80003496 <iget>
    80003702:	bf5d                	j	800036b8 <ialloc+0x86>

0000000080003704 <iupdate>:
{
    80003704:	1101                	addi	sp,sp,-32
    80003706:	ec06                	sd	ra,24(sp)
    80003708:	e822                	sd	s0,16(sp)
    8000370a:	e426                	sd	s1,8(sp)
    8000370c:	e04a                	sd	s2,0(sp)
    8000370e:	1000                	addi	s0,sp,32
    80003710:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003712:	415c                	lw	a5,4(a0)
    80003714:	0047d79b          	srliw	a5,a5,0x4
    80003718:	0001c597          	auipc	a1,0x1c
    8000371c:	dc85a583          	lw	a1,-568(a1) # 8001f4e0 <sb+0x18>
    80003720:	9dbd                	addw	a1,a1,a5
    80003722:	4108                	lw	a0,0(a0)
    80003724:	00000097          	auipc	ra,0x0
    80003728:	890080e7          	jalr	-1904(ra) # 80002fb4 <bread>
    8000372c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000372e:	05850793          	addi	a5,a0,88
    80003732:	40c8                	lw	a0,4(s1)
    80003734:	893d                	andi	a0,a0,15
    80003736:	051a                	slli	a0,a0,0x6
    80003738:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000373a:	04449703          	lh	a4,68(s1)
    8000373e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003742:	04649703          	lh	a4,70(s1)
    80003746:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000374a:	04849703          	lh	a4,72(s1)
    8000374e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003752:	04a49703          	lh	a4,74(s1)
    80003756:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000375a:	44f8                	lw	a4,76(s1)
    8000375c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000375e:	03400613          	li	a2,52
    80003762:	05048593          	addi	a1,s1,80
    80003766:	0531                	addi	a0,a0,12
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	5de080e7          	jalr	1502(ra) # 80000d46 <memmove>
  log_write(bp);
    80003770:	854a                	mv	a0,s2
    80003772:	00001097          	auipc	ra,0x1
    80003776:	bf6080e7          	jalr	-1034(ra) # 80004368 <log_write>
  brelse(bp);
    8000377a:	854a                	mv	a0,s2
    8000377c:	00000097          	auipc	ra,0x0
    80003780:	968080e7          	jalr	-1688(ra) # 800030e4 <brelse>
}
    80003784:	60e2                	ld	ra,24(sp)
    80003786:	6442                	ld	s0,16(sp)
    80003788:	64a2                	ld	s1,8(sp)
    8000378a:	6902                	ld	s2,0(sp)
    8000378c:	6105                	addi	sp,sp,32
    8000378e:	8082                	ret

0000000080003790 <idup>:
{
    80003790:	1101                	addi	sp,sp,-32
    80003792:	ec06                	sd	ra,24(sp)
    80003794:	e822                	sd	s0,16(sp)
    80003796:	e426                	sd	s1,8(sp)
    80003798:	1000                	addi	s0,sp,32
    8000379a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000379c:	0001c517          	auipc	a0,0x1c
    800037a0:	d4c50513          	addi	a0,a0,-692 # 8001f4e8 <itable>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	446080e7          	jalr	1094(ra) # 80000bea <acquire>
  ip->ref++;
    800037ac:	449c                	lw	a5,8(s1)
    800037ae:	2785                	addiw	a5,a5,1
    800037b0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037b2:	0001c517          	auipc	a0,0x1c
    800037b6:	d3650513          	addi	a0,a0,-714 # 8001f4e8 <itable>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	4e4080e7          	jalr	1252(ra) # 80000c9e <release>
}
    800037c2:	8526                	mv	a0,s1
    800037c4:	60e2                	ld	ra,24(sp)
    800037c6:	6442                	ld	s0,16(sp)
    800037c8:	64a2                	ld	s1,8(sp)
    800037ca:	6105                	addi	sp,sp,32
    800037cc:	8082                	ret

00000000800037ce <ilock>:
{
    800037ce:	1101                	addi	sp,sp,-32
    800037d0:	ec06                	sd	ra,24(sp)
    800037d2:	e822                	sd	s0,16(sp)
    800037d4:	e426                	sd	s1,8(sp)
    800037d6:	e04a                	sd	s2,0(sp)
    800037d8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037da:	c115                	beqz	a0,800037fe <ilock+0x30>
    800037dc:	84aa                	mv	s1,a0
    800037de:	451c                	lw	a5,8(a0)
    800037e0:	00f05f63          	blez	a5,800037fe <ilock+0x30>
  acquiresleep(&ip->lock);
    800037e4:	0541                	addi	a0,a0,16
    800037e6:	00001097          	auipc	ra,0x1
    800037ea:	ca2080e7          	jalr	-862(ra) # 80004488 <acquiresleep>
  if(ip->valid == 0){
    800037ee:	40bc                	lw	a5,64(s1)
    800037f0:	cf99                	beqz	a5,8000380e <ilock+0x40>
}
    800037f2:	60e2                	ld	ra,24(sp)
    800037f4:	6442                	ld	s0,16(sp)
    800037f6:	64a2                	ld	s1,8(sp)
    800037f8:	6902                	ld	s2,0(sp)
    800037fa:	6105                	addi	sp,sp,32
    800037fc:	8082                	ret
    panic("ilock");
    800037fe:	00005517          	auipc	a0,0x5
    80003802:	e3a50513          	addi	a0,a0,-454 # 80008638 <syscalls+0x190>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	d3e080e7          	jalr	-706(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000380e:	40dc                	lw	a5,4(s1)
    80003810:	0047d79b          	srliw	a5,a5,0x4
    80003814:	0001c597          	auipc	a1,0x1c
    80003818:	ccc5a583          	lw	a1,-820(a1) # 8001f4e0 <sb+0x18>
    8000381c:	9dbd                	addw	a1,a1,a5
    8000381e:	4088                	lw	a0,0(s1)
    80003820:	fffff097          	auipc	ra,0xfffff
    80003824:	794080e7          	jalr	1940(ra) # 80002fb4 <bread>
    80003828:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000382a:	05850593          	addi	a1,a0,88
    8000382e:	40dc                	lw	a5,4(s1)
    80003830:	8bbd                	andi	a5,a5,15
    80003832:	079a                	slli	a5,a5,0x6
    80003834:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003836:	00059783          	lh	a5,0(a1)
    8000383a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000383e:	00259783          	lh	a5,2(a1)
    80003842:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003846:	00459783          	lh	a5,4(a1)
    8000384a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000384e:	00659783          	lh	a5,6(a1)
    80003852:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003856:	459c                	lw	a5,8(a1)
    80003858:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000385a:	03400613          	li	a2,52
    8000385e:	05b1                	addi	a1,a1,12
    80003860:	05048513          	addi	a0,s1,80
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	4e2080e7          	jalr	1250(ra) # 80000d46 <memmove>
    brelse(bp);
    8000386c:	854a                	mv	a0,s2
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	876080e7          	jalr	-1930(ra) # 800030e4 <brelse>
    ip->valid = 1;
    80003876:	4785                	li	a5,1
    80003878:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000387a:	04449783          	lh	a5,68(s1)
    8000387e:	fbb5                	bnez	a5,800037f2 <ilock+0x24>
      panic("ilock: no type");
    80003880:	00005517          	auipc	a0,0x5
    80003884:	dc050513          	addi	a0,a0,-576 # 80008640 <syscalls+0x198>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	cbc080e7          	jalr	-836(ra) # 80000544 <panic>

0000000080003890 <iunlock>:
{
    80003890:	1101                	addi	sp,sp,-32
    80003892:	ec06                	sd	ra,24(sp)
    80003894:	e822                	sd	s0,16(sp)
    80003896:	e426                	sd	s1,8(sp)
    80003898:	e04a                	sd	s2,0(sp)
    8000389a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000389c:	c905                	beqz	a0,800038cc <iunlock+0x3c>
    8000389e:	84aa                	mv	s1,a0
    800038a0:	01050913          	addi	s2,a0,16
    800038a4:	854a                	mv	a0,s2
    800038a6:	00001097          	auipc	ra,0x1
    800038aa:	c7c080e7          	jalr	-900(ra) # 80004522 <holdingsleep>
    800038ae:	cd19                	beqz	a0,800038cc <iunlock+0x3c>
    800038b0:	449c                	lw	a5,8(s1)
    800038b2:	00f05d63          	blez	a5,800038cc <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038b6:	854a                	mv	a0,s2
    800038b8:	00001097          	auipc	ra,0x1
    800038bc:	c26080e7          	jalr	-986(ra) # 800044de <releasesleep>
}
    800038c0:	60e2                	ld	ra,24(sp)
    800038c2:	6442                	ld	s0,16(sp)
    800038c4:	64a2                	ld	s1,8(sp)
    800038c6:	6902                	ld	s2,0(sp)
    800038c8:	6105                	addi	sp,sp,32
    800038ca:	8082                	ret
    panic("iunlock");
    800038cc:	00005517          	auipc	a0,0x5
    800038d0:	d8450513          	addi	a0,a0,-636 # 80008650 <syscalls+0x1a8>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	c70080e7          	jalr	-912(ra) # 80000544 <panic>

00000000800038dc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038dc:	7179                	addi	sp,sp,-48
    800038de:	f406                	sd	ra,40(sp)
    800038e0:	f022                	sd	s0,32(sp)
    800038e2:	ec26                	sd	s1,24(sp)
    800038e4:	e84a                	sd	s2,16(sp)
    800038e6:	e44e                	sd	s3,8(sp)
    800038e8:	e052                	sd	s4,0(sp)
    800038ea:	1800                	addi	s0,sp,48
    800038ec:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038ee:	05050493          	addi	s1,a0,80
    800038f2:	08050913          	addi	s2,a0,128
    800038f6:	a021                	j	800038fe <itrunc+0x22>
    800038f8:	0491                	addi	s1,s1,4
    800038fa:	01248d63          	beq	s1,s2,80003914 <itrunc+0x38>
    if(ip->addrs[i]){
    800038fe:	408c                	lw	a1,0(s1)
    80003900:	dde5                	beqz	a1,800038f8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003902:	0009a503          	lw	a0,0(s3)
    80003906:	00000097          	auipc	ra,0x0
    8000390a:	8f4080e7          	jalr	-1804(ra) # 800031fa <bfree>
      ip->addrs[i] = 0;
    8000390e:	0004a023          	sw	zero,0(s1)
    80003912:	b7dd                	j	800038f8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003914:	0809a583          	lw	a1,128(s3)
    80003918:	e185                	bnez	a1,80003938 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000391a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000391e:	854e                	mv	a0,s3
    80003920:	00000097          	auipc	ra,0x0
    80003924:	de4080e7          	jalr	-540(ra) # 80003704 <iupdate>
}
    80003928:	70a2                	ld	ra,40(sp)
    8000392a:	7402                	ld	s0,32(sp)
    8000392c:	64e2                	ld	s1,24(sp)
    8000392e:	6942                	ld	s2,16(sp)
    80003930:	69a2                	ld	s3,8(sp)
    80003932:	6a02                	ld	s4,0(sp)
    80003934:	6145                	addi	sp,sp,48
    80003936:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003938:	0009a503          	lw	a0,0(s3)
    8000393c:	fffff097          	auipc	ra,0xfffff
    80003940:	678080e7          	jalr	1656(ra) # 80002fb4 <bread>
    80003944:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003946:	05850493          	addi	s1,a0,88
    8000394a:	45850913          	addi	s2,a0,1112
    8000394e:	a811                	j	80003962 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003950:	0009a503          	lw	a0,0(s3)
    80003954:	00000097          	auipc	ra,0x0
    80003958:	8a6080e7          	jalr	-1882(ra) # 800031fa <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000395c:	0491                	addi	s1,s1,4
    8000395e:	01248563          	beq	s1,s2,80003968 <itrunc+0x8c>
      if(a[j])
    80003962:	408c                	lw	a1,0(s1)
    80003964:	dde5                	beqz	a1,8000395c <itrunc+0x80>
    80003966:	b7ed                	j	80003950 <itrunc+0x74>
    brelse(bp);
    80003968:	8552                	mv	a0,s4
    8000396a:	fffff097          	auipc	ra,0xfffff
    8000396e:	77a080e7          	jalr	1914(ra) # 800030e4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003972:	0809a583          	lw	a1,128(s3)
    80003976:	0009a503          	lw	a0,0(s3)
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	880080e7          	jalr	-1920(ra) # 800031fa <bfree>
    ip->addrs[NDIRECT] = 0;
    80003982:	0809a023          	sw	zero,128(s3)
    80003986:	bf51                	j	8000391a <itrunc+0x3e>

0000000080003988 <iput>:
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	e04a                	sd	s2,0(sp)
    80003992:	1000                	addi	s0,sp,32
    80003994:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003996:	0001c517          	auipc	a0,0x1c
    8000399a:	b5250513          	addi	a0,a0,-1198 # 8001f4e8 <itable>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	24c080e7          	jalr	588(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039a6:	4498                	lw	a4,8(s1)
    800039a8:	4785                	li	a5,1
    800039aa:	02f70363          	beq	a4,a5,800039d0 <iput+0x48>
  ip->ref--;
    800039ae:	449c                	lw	a5,8(s1)
    800039b0:	37fd                	addiw	a5,a5,-1
    800039b2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039b4:	0001c517          	auipc	a0,0x1c
    800039b8:	b3450513          	addi	a0,a0,-1228 # 8001f4e8 <itable>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	2e2080e7          	jalr	738(ra) # 80000c9e <release>
}
    800039c4:	60e2                	ld	ra,24(sp)
    800039c6:	6442                	ld	s0,16(sp)
    800039c8:	64a2                	ld	s1,8(sp)
    800039ca:	6902                	ld	s2,0(sp)
    800039cc:	6105                	addi	sp,sp,32
    800039ce:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039d0:	40bc                	lw	a5,64(s1)
    800039d2:	dff1                	beqz	a5,800039ae <iput+0x26>
    800039d4:	04a49783          	lh	a5,74(s1)
    800039d8:	fbf9                	bnez	a5,800039ae <iput+0x26>
    acquiresleep(&ip->lock);
    800039da:	01048913          	addi	s2,s1,16
    800039de:	854a                	mv	a0,s2
    800039e0:	00001097          	auipc	ra,0x1
    800039e4:	aa8080e7          	jalr	-1368(ra) # 80004488 <acquiresleep>
    release(&itable.lock);
    800039e8:	0001c517          	auipc	a0,0x1c
    800039ec:	b0050513          	addi	a0,a0,-1280 # 8001f4e8 <itable>
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	2ae080e7          	jalr	686(ra) # 80000c9e <release>
    itrunc(ip);
    800039f8:	8526                	mv	a0,s1
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	ee2080e7          	jalr	-286(ra) # 800038dc <itrunc>
    ip->type = 0;
    80003a02:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a06:	8526                	mv	a0,s1
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	cfc080e7          	jalr	-772(ra) # 80003704 <iupdate>
    ip->valid = 0;
    80003a10:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a14:	854a                	mv	a0,s2
    80003a16:	00001097          	auipc	ra,0x1
    80003a1a:	ac8080e7          	jalr	-1336(ra) # 800044de <releasesleep>
    acquire(&itable.lock);
    80003a1e:	0001c517          	auipc	a0,0x1c
    80003a22:	aca50513          	addi	a0,a0,-1334 # 8001f4e8 <itable>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	1c4080e7          	jalr	452(ra) # 80000bea <acquire>
    80003a2e:	b741                	j	800039ae <iput+0x26>

0000000080003a30 <iunlockput>:
{
    80003a30:	1101                	addi	sp,sp,-32
    80003a32:	ec06                	sd	ra,24(sp)
    80003a34:	e822                	sd	s0,16(sp)
    80003a36:	e426                	sd	s1,8(sp)
    80003a38:	1000                	addi	s0,sp,32
    80003a3a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	e54080e7          	jalr	-428(ra) # 80003890 <iunlock>
  iput(ip);
    80003a44:	8526                	mv	a0,s1
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	f42080e7          	jalr	-190(ra) # 80003988 <iput>
}
    80003a4e:	60e2                	ld	ra,24(sp)
    80003a50:	6442                	ld	s0,16(sp)
    80003a52:	64a2                	ld	s1,8(sp)
    80003a54:	6105                	addi	sp,sp,32
    80003a56:	8082                	ret

0000000080003a58 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a58:	1141                	addi	sp,sp,-16
    80003a5a:	e422                	sd	s0,8(sp)
    80003a5c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a5e:	411c                	lw	a5,0(a0)
    80003a60:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a62:	415c                	lw	a5,4(a0)
    80003a64:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a66:	04451783          	lh	a5,68(a0)
    80003a6a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a6e:	04a51783          	lh	a5,74(a0)
    80003a72:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a76:	04c56783          	lwu	a5,76(a0)
    80003a7a:	e99c                	sd	a5,16(a1)
}
    80003a7c:	6422                	ld	s0,8(sp)
    80003a7e:	0141                	addi	sp,sp,16
    80003a80:	8082                	ret

0000000080003a82 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a82:	457c                	lw	a5,76(a0)
    80003a84:	0ed7e963          	bltu	a5,a3,80003b76 <readi+0xf4>
{
    80003a88:	7159                	addi	sp,sp,-112
    80003a8a:	f486                	sd	ra,104(sp)
    80003a8c:	f0a2                	sd	s0,96(sp)
    80003a8e:	eca6                	sd	s1,88(sp)
    80003a90:	e8ca                	sd	s2,80(sp)
    80003a92:	e4ce                	sd	s3,72(sp)
    80003a94:	e0d2                	sd	s4,64(sp)
    80003a96:	fc56                	sd	s5,56(sp)
    80003a98:	f85a                	sd	s6,48(sp)
    80003a9a:	f45e                	sd	s7,40(sp)
    80003a9c:	f062                	sd	s8,32(sp)
    80003a9e:	ec66                	sd	s9,24(sp)
    80003aa0:	e86a                	sd	s10,16(sp)
    80003aa2:	e46e                	sd	s11,8(sp)
    80003aa4:	1880                	addi	s0,sp,112
    80003aa6:	8b2a                	mv	s6,a0
    80003aa8:	8bae                	mv	s7,a1
    80003aaa:	8a32                	mv	s4,a2
    80003aac:	84b6                	mv	s1,a3
    80003aae:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ab0:	9f35                	addw	a4,a4,a3
    return 0;
    80003ab2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ab4:	0ad76063          	bltu	a4,a3,80003b54 <readi+0xd2>
  if(off + n > ip->size)
    80003ab8:	00e7f463          	bgeu	a5,a4,80003ac0 <readi+0x3e>
    n = ip->size - off;
    80003abc:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac0:	0a0a8963          	beqz	s5,80003b72 <readi+0xf0>
    80003ac4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aca:	5c7d                	li	s8,-1
    80003acc:	a82d                	j	80003b06 <readi+0x84>
    80003ace:	020d1d93          	slli	s11,s10,0x20
    80003ad2:	020ddd93          	srli	s11,s11,0x20
    80003ad6:	05890613          	addi	a2,s2,88
    80003ada:	86ee                	mv	a3,s11
    80003adc:	963a                	add	a2,a2,a4
    80003ade:	85d2                	mv	a1,s4
    80003ae0:	855e                	mv	a0,s7
    80003ae2:	fffff097          	auipc	ra,0xfffff
    80003ae6:	a08080e7          	jalr	-1528(ra) # 800024ea <either_copyout>
    80003aea:	05850d63          	beq	a0,s8,80003b44 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003aee:	854a                	mv	a0,s2
    80003af0:	fffff097          	auipc	ra,0xfffff
    80003af4:	5f4080e7          	jalr	1524(ra) # 800030e4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af8:	013d09bb          	addw	s3,s10,s3
    80003afc:	009d04bb          	addw	s1,s10,s1
    80003b00:	9a6e                	add	s4,s4,s11
    80003b02:	0559f763          	bgeu	s3,s5,80003b50 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b06:	00a4d59b          	srliw	a1,s1,0xa
    80003b0a:	855a                	mv	a0,s6
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	8a2080e7          	jalr	-1886(ra) # 800033ae <bmap>
    80003b14:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b18:	cd85                	beqz	a1,80003b50 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b1a:	000b2503          	lw	a0,0(s6)
    80003b1e:	fffff097          	auipc	ra,0xfffff
    80003b22:	496080e7          	jalr	1174(ra) # 80002fb4 <bread>
    80003b26:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b28:	3ff4f713          	andi	a4,s1,1023
    80003b2c:	40ec87bb          	subw	a5,s9,a4
    80003b30:	413a86bb          	subw	a3,s5,s3
    80003b34:	8d3e                	mv	s10,a5
    80003b36:	2781                	sext.w	a5,a5
    80003b38:	0006861b          	sext.w	a2,a3
    80003b3c:	f8f679e3          	bgeu	a2,a5,80003ace <readi+0x4c>
    80003b40:	8d36                	mv	s10,a3
    80003b42:	b771                	j	80003ace <readi+0x4c>
      brelse(bp);
    80003b44:	854a                	mv	a0,s2
    80003b46:	fffff097          	auipc	ra,0xfffff
    80003b4a:	59e080e7          	jalr	1438(ra) # 800030e4 <brelse>
      tot = -1;
    80003b4e:	59fd                	li	s3,-1
  }
  return tot;
    80003b50:	0009851b          	sext.w	a0,s3
}
    80003b54:	70a6                	ld	ra,104(sp)
    80003b56:	7406                	ld	s0,96(sp)
    80003b58:	64e6                	ld	s1,88(sp)
    80003b5a:	6946                	ld	s2,80(sp)
    80003b5c:	69a6                	ld	s3,72(sp)
    80003b5e:	6a06                	ld	s4,64(sp)
    80003b60:	7ae2                	ld	s5,56(sp)
    80003b62:	7b42                	ld	s6,48(sp)
    80003b64:	7ba2                	ld	s7,40(sp)
    80003b66:	7c02                	ld	s8,32(sp)
    80003b68:	6ce2                	ld	s9,24(sp)
    80003b6a:	6d42                	ld	s10,16(sp)
    80003b6c:	6da2                	ld	s11,8(sp)
    80003b6e:	6165                	addi	sp,sp,112
    80003b70:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b72:	89d6                	mv	s3,s5
    80003b74:	bff1                	j	80003b50 <readi+0xce>
    return 0;
    80003b76:	4501                	li	a0,0
}
    80003b78:	8082                	ret

0000000080003b7a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b7a:	457c                	lw	a5,76(a0)
    80003b7c:	10d7e863          	bltu	a5,a3,80003c8c <writei+0x112>
{
    80003b80:	7159                	addi	sp,sp,-112
    80003b82:	f486                	sd	ra,104(sp)
    80003b84:	f0a2                	sd	s0,96(sp)
    80003b86:	eca6                	sd	s1,88(sp)
    80003b88:	e8ca                	sd	s2,80(sp)
    80003b8a:	e4ce                	sd	s3,72(sp)
    80003b8c:	e0d2                	sd	s4,64(sp)
    80003b8e:	fc56                	sd	s5,56(sp)
    80003b90:	f85a                	sd	s6,48(sp)
    80003b92:	f45e                	sd	s7,40(sp)
    80003b94:	f062                	sd	s8,32(sp)
    80003b96:	ec66                	sd	s9,24(sp)
    80003b98:	e86a                	sd	s10,16(sp)
    80003b9a:	e46e                	sd	s11,8(sp)
    80003b9c:	1880                	addi	s0,sp,112
    80003b9e:	8aaa                	mv	s5,a0
    80003ba0:	8bae                	mv	s7,a1
    80003ba2:	8a32                	mv	s4,a2
    80003ba4:	8936                	mv	s2,a3
    80003ba6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ba8:	00e687bb          	addw	a5,a3,a4
    80003bac:	0ed7e263          	bltu	a5,a3,80003c90 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bb0:	00043737          	lui	a4,0x43
    80003bb4:	0ef76063          	bltu	a4,a5,80003c94 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb8:	0c0b0863          	beqz	s6,80003c88 <writei+0x10e>
    80003bbc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bbe:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bc2:	5c7d                	li	s8,-1
    80003bc4:	a091                	j	80003c08 <writei+0x8e>
    80003bc6:	020d1d93          	slli	s11,s10,0x20
    80003bca:	020ddd93          	srli	s11,s11,0x20
    80003bce:	05848513          	addi	a0,s1,88
    80003bd2:	86ee                	mv	a3,s11
    80003bd4:	8652                	mv	a2,s4
    80003bd6:	85de                	mv	a1,s7
    80003bd8:	953a                	add	a0,a0,a4
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	966080e7          	jalr	-1690(ra) # 80002540 <either_copyin>
    80003be2:	07850263          	beq	a0,s8,80003c46 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003be6:	8526                	mv	a0,s1
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	780080e7          	jalr	1920(ra) # 80004368 <log_write>
    brelse(bp);
    80003bf0:	8526                	mv	a0,s1
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	4f2080e7          	jalr	1266(ra) # 800030e4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bfa:	013d09bb          	addw	s3,s10,s3
    80003bfe:	012d093b          	addw	s2,s10,s2
    80003c02:	9a6e                	add	s4,s4,s11
    80003c04:	0569f663          	bgeu	s3,s6,80003c50 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c08:	00a9559b          	srliw	a1,s2,0xa
    80003c0c:	8556                	mv	a0,s5
    80003c0e:	fffff097          	auipc	ra,0xfffff
    80003c12:	7a0080e7          	jalr	1952(ra) # 800033ae <bmap>
    80003c16:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c1a:	c99d                	beqz	a1,80003c50 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c1c:	000aa503          	lw	a0,0(s5)
    80003c20:	fffff097          	auipc	ra,0xfffff
    80003c24:	394080e7          	jalr	916(ra) # 80002fb4 <bread>
    80003c28:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2a:	3ff97713          	andi	a4,s2,1023
    80003c2e:	40ec87bb          	subw	a5,s9,a4
    80003c32:	413b06bb          	subw	a3,s6,s3
    80003c36:	8d3e                	mv	s10,a5
    80003c38:	2781                	sext.w	a5,a5
    80003c3a:	0006861b          	sext.w	a2,a3
    80003c3e:	f8f674e3          	bgeu	a2,a5,80003bc6 <writei+0x4c>
    80003c42:	8d36                	mv	s10,a3
    80003c44:	b749                	j	80003bc6 <writei+0x4c>
      brelse(bp);
    80003c46:	8526                	mv	a0,s1
    80003c48:	fffff097          	auipc	ra,0xfffff
    80003c4c:	49c080e7          	jalr	1180(ra) # 800030e4 <brelse>
  }

  if(off > ip->size)
    80003c50:	04caa783          	lw	a5,76(s5)
    80003c54:	0127f463          	bgeu	a5,s2,80003c5c <writei+0xe2>
    ip->size = off;
    80003c58:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c5c:	8556                	mv	a0,s5
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	aa6080e7          	jalr	-1370(ra) # 80003704 <iupdate>

  return tot;
    80003c66:	0009851b          	sext.w	a0,s3
}
    80003c6a:	70a6                	ld	ra,104(sp)
    80003c6c:	7406                	ld	s0,96(sp)
    80003c6e:	64e6                	ld	s1,88(sp)
    80003c70:	6946                	ld	s2,80(sp)
    80003c72:	69a6                	ld	s3,72(sp)
    80003c74:	6a06                	ld	s4,64(sp)
    80003c76:	7ae2                	ld	s5,56(sp)
    80003c78:	7b42                	ld	s6,48(sp)
    80003c7a:	7ba2                	ld	s7,40(sp)
    80003c7c:	7c02                	ld	s8,32(sp)
    80003c7e:	6ce2                	ld	s9,24(sp)
    80003c80:	6d42                	ld	s10,16(sp)
    80003c82:	6da2                	ld	s11,8(sp)
    80003c84:	6165                	addi	sp,sp,112
    80003c86:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c88:	89da                	mv	s3,s6
    80003c8a:	bfc9                	j	80003c5c <writei+0xe2>
    return -1;
    80003c8c:	557d                	li	a0,-1
}
    80003c8e:	8082                	ret
    return -1;
    80003c90:	557d                	li	a0,-1
    80003c92:	bfe1                	j	80003c6a <writei+0xf0>
    return -1;
    80003c94:	557d                	li	a0,-1
    80003c96:	bfd1                	j	80003c6a <writei+0xf0>

0000000080003c98 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c98:	1141                	addi	sp,sp,-16
    80003c9a:	e406                	sd	ra,8(sp)
    80003c9c:	e022                	sd	s0,0(sp)
    80003c9e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ca0:	4639                	li	a2,14
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	11c080e7          	jalr	284(ra) # 80000dbe <strncmp>
}
    80003caa:	60a2                	ld	ra,8(sp)
    80003cac:	6402                	ld	s0,0(sp)
    80003cae:	0141                	addi	sp,sp,16
    80003cb0:	8082                	ret

0000000080003cb2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cb2:	7139                	addi	sp,sp,-64
    80003cb4:	fc06                	sd	ra,56(sp)
    80003cb6:	f822                	sd	s0,48(sp)
    80003cb8:	f426                	sd	s1,40(sp)
    80003cba:	f04a                	sd	s2,32(sp)
    80003cbc:	ec4e                	sd	s3,24(sp)
    80003cbe:	e852                	sd	s4,16(sp)
    80003cc0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cc2:	04451703          	lh	a4,68(a0)
    80003cc6:	4785                	li	a5,1
    80003cc8:	00f71a63          	bne	a4,a5,80003cdc <dirlookup+0x2a>
    80003ccc:	892a                	mv	s2,a0
    80003cce:	89ae                	mv	s3,a1
    80003cd0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd2:	457c                	lw	a5,76(a0)
    80003cd4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cd6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd8:	e79d                	bnez	a5,80003d06 <dirlookup+0x54>
    80003cda:	a8a5                	j	80003d52 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cdc:	00005517          	auipc	a0,0x5
    80003ce0:	97c50513          	addi	a0,a0,-1668 # 80008658 <syscalls+0x1b0>
    80003ce4:	ffffd097          	auipc	ra,0xffffd
    80003ce8:	860080e7          	jalr	-1952(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003cec:	00005517          	auipc	a0,0x5
    80003cf0:	98450513          	addi	a0,a0,-1660 # 80008670 <syscalls+0x1c8>
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	850080e7          	jalr	-1968(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cfc:	24c1                	addiw	s1,s1,16
    80003cfe:	04c92783          	lw	a5,76(s2)
    80003d02:	04f4f763          	bgeu	s1,a5,80003d50 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d06:	4741                	li	a4,16
    80003d08:	86a6                	mv	a3,s1
    80003d0a:	fc040613          	addi	a2,s0,-64
    80003d0e:	4581                	li	a1,0
    80003d10:	854a                	mv	a0,s2
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	d70080e7          	jalr	-656(ra) # 80003a82 <readi>
    80003d1a:	47c1                	li	a5,16
    80003d1c:	fcf518e3          	bne	a0,a5,80003cec <dirlookup+0x3a>
    if(de.inum == 0)
    80003d20:	fc045783          	lhu	a5,-64(s0)
    80003d24:	dfe1                	beqz	a5,80003cfc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d26:	fc240593          	addi	a1,s0,-62
    80003d2a:	854e                	mv	a0,s3
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	f6c080e7          	jalr	-148(ra) # 80003c98 <namecmp>
    80003d34:	f561                	bnez	a0,80003cfc <dirlookup+0x4a>
      if(poff)
    80003d36:	000a0463          	beqz	s4,80003d3e <dirlookup+0x8c>
        *poff = off;
    80003d3a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d3e:	fc045583          	lhu	a1,-64(s0)
    80003d42:	00092503          	lw	a0,0(s2)
    80003d46:	fffff097          	auipc	ra,0xfffff
    80003d4a:	750080e7          	jalr	1872(ra) # 80003496 <iget>
    80003d4e:	a011                	j	80003d52 <dirlookup+0xa0>
  return 0;
    80003d50:	4501                	li	a0,0
}
    80003d52:	70e2                	ld	ra,56(sp)
    80003d54:	7442                	ld	s0,48(sp)
    80003d56:	74a2                	ld	s1,40(sp)
    80003d58:	7902                	ld	s2,32(sp)
    80003d5a:	69e2                	ld	s3,24(sp)
    80003d5c:	6a42                	ld	s4,16(sp)
    80003d5e:	6121                	addi	sp,sp,64
    80003d60:	8082                	ret

0000000080003d62 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d62:	711d                	addi	sp,sp,-96
    80003d64:	ec86                	sd	ra,88(sp)
    80003d66:	e8a2                	sd	s0,80(sp)
    80003d68:	e4a6                	sd	s1,72(sp)
    80003d6a:	e0ca                	sd	s2,64(sp)
    80003d6c:	fc4e                	sd	s3,56(sp)
    80003d6e:	f852                	sd	s4,48(sp)
    80003d70:	f456                	sd	s5,40(sp)
    80003d72:	f05a                	sd	s6,32(sp)
    80003d74:	ec5e                	sd	s7,24(sp)
    80003d76:	e862                	sd	s8,16(sp)
    80003d78:	e466                	sd	s9,8(sp)
    80003d7a:	1080                	addi	s0,sp,96
    80003d7c:	84aa                	mv	s1,a0
    80003d7e:	8b2e                	mv	s6,a1
    80003d80:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d82:	00054703          	lbu	a4,0(a0)
    80003d86:	02f00793          	li	a5,47
    80003d8a:	02f70363          	beq	a4,a5,80003db0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d8e:	ffffe097          	auipc	ra,0xffffe
    80003d92:	c38080e7          	jalr	-968(ra) # 800019c6 <myproc>
    80003d96:	16053503          	ld	a0,352(a0)
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	9f6080e7          	jalr	-1546(ra) # 80003790 <idup>
    80003da2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003da4:	02f00913          	li	s2,47
  len = path - s;
    80003da8:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003daa:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dac:	4c05                	li	s8,1
    80003dae:	a865                	j	80003e66 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003db0:	4585                	li	a1,1
    80003db2:	4505                	li	a0,1
    80003db4:	fffff097          	auipc	ra,0xfffff
    80003db8:	6e2080e7          	jalr	1762(ra) # 80003496 <iget>
    80003dbc:	89aa                	mv	s3,a0
    80003dbe:	b7dd                	j	80003da4 <namex+0x42>
      iunlockput(ip);
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	c6e080e7          	jalr	-914(ra) # 80003a30 <iunlockput>
      return 0;
    80003dca:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dcc:	854e                	mv	a0,s3
    80003dce:	60e6                	ld	ra,88(sp)
    80003dd0:	6446                	ld	s0,80(sp)
    80003dd2:	64a6                	ld	s1,72(sp)
    80003dd4:	6906                	ld	s2,64(sp)
    80003dd6:	79e2                	ld	s3,56(sp)
    80003dd8:	7a42                	ld	s4,48(sp)
    80003dda:	7aa2                	ld	s5,40(sp)
    80003ddc:	7b02                	ld	s6,32(sp)
    80003dde:	6be2                	ld	s7,24(sp)
    80003de0:	6c42                	ld	s8,16(sp)
    80003de2:	6ca2                	ld	s9,8(sp)
    80003de4:	6125                	addi	sp,sp,96
    80003de6:	8082                	ret
      iunlock(ip);
    80003de8:	854e                	mv	a0,s3
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	aa6080e7          	jalr	-1370(ra) # 80003890 <iunlock>
      return ip;
    80003df2:	bfe9                	j	80003dcc <namex+0x6a>
      iunlockput(ip);
    80003df4:	854e                	mv	a0,s3
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	c3a080e7          	jalr	-966(ra) # 80003a30 <iunlockput>
      return 0;
    80003dfe:	89d2                	mv	s3,s4
    80003e00:	b7f1                	j	80003dcc <namex+0x6a>
  len = path - s;
    80003e02:	40b48633          	sub	a2,s1,a1
    80003e06:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e0a:	094cd463          	bge	s9,s4,80003e92 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e0e:	4639                	li	a2,14
    80003e10:	8556                	mv	a0,s5
    80003e12:	ffffd097          	auipc	ra,0xffffd
    80003e16:	f34080e7          	jalr	-204(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003e1a:	0004c783          	lbu	a5,0(s1)
    80003e1e:	01279763          	bne	a5,s2,80003e2c <namex+0xca>
    path++;
    80003e22:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e24:	0004c783          	lbu	a5,0(s1)
    80003e28:	ff278de3          	beq	a5,s2,80003e22 <namex+0xc0>
    ilock(ip);
    80003e2c:	854e                	mv	a0,s3
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	9a0080e7          	jalr	-1632(ra) # 800037ce <ilock>
    if(ip->type != T_DIR){
    80003e36:	04499783          	lh	a5,68(s3)
    80003e3a:	f98793e3          	bne	a5,s8,80003dc0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e3e:	000b0563          	beqz	s6,80003e48 <namex+0xe6>
    80003e42:	0004c783          	lbu	a5,0(s1)
    80003e46:	d3cd                	beqz	a5,80003de8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e48:	865e                	mv	a2,s7
    80003e4a:	85d6                	mv	a1,s5
    80003e4c:	854e                	mv	a0,s3
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	e64080e7          	jalr	-412(ra) # 80003cb2 <dirlookup>
    80003e56:	8a2a                	mv	s4,a0
    80003e58:	dd51                	beqz	a0,80003df4 <namex+0x92>
    iunlockput(ip);
    80003e5a:	854e                	mv	a0,s3
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	bd4080e7          	jalr	-1068(ra) # 80003a30 <iunlockput>
    ip = next;
    80003e64:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e66:	0004c783          	lbu	a5,0(s1)
    80003e6a:	05279763          	bne	a5,s2,80003eb8 <namex+0x156>
    path++;
    80003e6e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	ff278de3          	beq	a5,s2,80003e6e <namex+0x10c>
  if(*path == 0)
    80003e78:	c79d                	beqz	a5,80003ea6 <namex+0x144>
    path++;
    80003e7a:	85a6                	mv	a1,s1
  len = path - s;
    80003e7c:	8a5e                	mv	s4,s7
    80003e7e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e80:	01278963          	beq	a5,s2,80003e92 <namex+0x130>
    80003e84:	dfbd                	beqz	a5,80003e02 <namex+0xa0>
    path++;
    80003e86:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e88:	0004c783          	lbu	a5,0(s1)
    80003e8c:	ff279ce3          	bne	a5,s2,80003e84 <namex+0x122>
    80003e90:	bf8d                	j	80003e02 <namex+0xa0>
    memmove(name, s, len);
    80003e92:	2601                	sext.w	a2,a2
    80003e94:	8556                	mv	a0,s5
    80003e96:	ffffd097          	auipc	ra,0xffffd
    80003e9a:	eb0080e7          	jalr	-336(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003e9e:	9a56                	add	s4,s4,s5
    80003ea0:	000a0023          	sb	zero,0(s4)
    80003ea4:	bf9d                	j	80003e1a <namex+0xb8>
  if(nameiparent){
    80003ea6:	f20b03e3          	beqz	s6,80003dcc <namex+0x6a>
    iput(ip);
    80003eaa:	854e                	mv	a0,s3
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	adc080e7          	jalr	-1316(ra) # 80003988 <iput>
    return 0;
    80003eb4:	4981                	li	s3,0
    80003eb6:	bf19                	j	80003dcc <namex+0x6a>
  if(*path == 0)
    80003eb8:	d7fd                	beqz	a5,80003ea6 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003eba:	0004c783          	lbu	a5,0(s1)
    80003ebe:	85a6                	mv	a1,s1
    80003ec0:	b7d1                	j	80003e84 <namex+0x122>

0000000080003ec2 <dirlink>:
{
    80003ec2:	7139                	addi	sp,sp,-64
    80003ec4:	fc06                	sd	ra,56(sp)
    80003ec6:	f822                	sd	s0,48(sp)
    80003ec8:	f426                	sd	s1,40(sp)
    80003eca:	f04a                	sd	s2,32(sp)
    80003ecc:	ec4e                	sd	s3,24(sp)
    80003ece:	e852                	sd	s4,16(sp)
    80003ed0:	0080                	addi	s0,sp,64
    80003ed2:	892a                	mv	s2,a0
    80003ed4:	8a2e                	mv	s4,a1
    80003ed6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ed8:	4601                	li	a2,0
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	dd8080e7          	jalr	-552(ra) # 80003cb2 <dirlookup>
    80003ee2:	e93d                	bnez	a0,80003f58 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee4:	04c92483          	lw	s1,76(s2)
    80003ee8:	c49d                	beqz	s1,80003f16 <dirlink+0x54>
    80003eea:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eec:	4741                	li	a4,16
    80003eee:	86a6                	mv	a3,s1
    80003ef0:	fc040613          	addi	a2,s0,-64
    80003ef4:	4581                	li	a1,0
    80003ef6:	854a                	mv	a0,s2
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	b8a080e7          	jalr	-1142(ra) # 80003a82 <readi>
    80003f00:	47c1                	li	a5,16
    80003f02:	06f51163          	bne	a0,a5,80003f64 <dirlink+0xa2>
    if(de.inum == 0)
    80003f06:	fc045783          	lhu	a5,-64(s0)
    80003f0a:	c791                	beqz	a5,80003f16 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f0c:	24c1                	addiw	s1,s1,16
    80003f0e:	04c92783          	lw	a5,76(s2)
    80003f12:	fcf4ede3          	bltu	s1,a5,80003eec <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f16:	4639                	li	a2,14
    80003f18:	85d2                	mv	a1,s4
    80003f1a:	fc240513          	addi	a0,s0,-62
    80003f1e:	ffffd097          	auipc	ra,0xffffd
    80003f22:	edc080e7          	jalr	-292(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003f26:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f2a:	4741                	li	a4,16
    80003f2c:	86a6                	mv	a3,s1
    80003f2e:	fc040613          	addi	a2,s0,-64
    80003f32:	4581                	li	a1,0
    80003f34:	854a                	mv	a0,s2
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	c44080e7          	jalr	-956(ra) # 80003b7a <writei>
    80003f3e:	1541                	addi	a0,a0,-16
    80003f40:	00a03533          	snez	a0,a0
    80003f44:	40a00533          	neg	a0,a0
}
    80003f48:	70e2                	ld	ra,56(sp)
    80003f4a:	7442                	ld	s0,48(sp)
    80003f4c:	74a2                	ld	s1,40(sp)
    80003f4e:	7902                	ld	s2,32(sp)
    80003f50:	69e2                	ld	s3,24(sp)
    80003f52:	6a42                	ld	s4,16(sp)
    80003f54:	6121                	addi	sp,sp,64
    80003f56:	8082                	ret
    iput(ip);
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	a30080e7          	jalr	-1488(ra) # 80003988 <iput>
    return -1;
    80003f60:	557d                	li	a0,-1
    80003f62:	b7dd                	j	80003f48 <dirlink+0x86>
      panic("dirlink read");
    80003f64:	00004517          	auipc	a0,0x4
    80003f68:	71c50513          	addi	a0,a0,1820 # 80008680 <syscalls+0x1d8>
    80003f6c:	ffffc097          	auipc	ra,0xffffc
    80003f70:	5d8080e7          	jalr	1496(ra) # 80000544 <panic>

0000000080003f74 <namei>:

struct inode*
namei(char *path)
{
    80003f74:	1101                	addi	sp,sp,-32
    80003f76:	ec06                	sd	ra,24(sp)
    80003f78:	e822                	sd	s0,16(sp)
    80003f7a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f7c:	fe040613          	addi	a2,s0,-32
    80003f80:	4581                	li	a1,0
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	de0080e7          	jalr	-544(ra) # 80003d62 <namex>
}
    80003f8a:	60e2                	ld	ra,24(sp)
    80003f8c:	6442                	ld	s0,16(sp)
    80003f8e:	6105                	addi	sp,sp,32
    80003f90:	8082                	ret

0000000080003f92 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f92:	1141                	addi	sp,sp,-16
    80003f94:	e406                	sd	ra,8(sp)
    80003f96:	e022                	sd	s0,0(sp)
    80003f98:	0800                	addi	s0,sp,16
    80003f9a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f9c:	4585                	li	a1,1
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	dc4080e7          	jalr	-572(ra) # 80003d62 <namex>
}
    80003fa6:	60a2                	ld	ra,8(sp)
    80003fa8:	6402                	ld	s0,0(sp)
    80003faa:	0141                	addi	sp,sp,16
    80003fac:	8082                	ret

0000000080003fae <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fae:	1101                	addi	sp,sp,-32
    80003fb0:	ec06                	sd	ra,24(sp)
    80003fb2:	e822                	sd	s0,16(sp)
    80003fb4:	e426                	sd	s1,8(sp)
    80003fb6:	e04a                	sd	s2,0(sp)
    80003fb8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fba:	0001d917          	auipc	s2,0x1d
    80003fbe:	fd690913          	addi	s2,s2,-42 # 80020f90 <log>
    80003fc2:	01892583          	lw	a1,24(s2)
    80003fc6:	02892503          	lw	a0,40(s2)
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	fea080e7          	jalr	-22(ra) # 80002fb4 <bread>
    80003fd2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fd4:	02c92683          	lw	a3,44(s2)
    80003fd8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fda:	02d05763          	blez	a3,80004008 <write_head+0x5a>
    80003fde:	0001d797          	auipc	a5,0x1d
    80003fe2:	fe278793          	addi	a5,a5,-30 # 80020fc0 <log+0x30>
    80003fe6:	05c50713          	addi	a4,a0,92
    80003fea:	36fd                	addiw	a3,a3,-1
    80003fec:	1682                	slli	a3,a3,0x20
    80003fee:	9281                	srli	a3,a3,0x20
    80003ff0:	068a                	slli	a3,a3,0x2
    80003ff2:	0001d617          	auipc	a2,0x1d
    80003ff6:	fd260613          	addi	a2,a2,-46 # 80020fc4 <log+0x34>
    80003ffa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ffc:	4390                	lw	a2,0(a5)
    80003ffe:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004000:	0791                	addi	a5,a5,4
    80004002:	0711                	addi	a4,a4,4
    80004004:	fed79ce3          	bne	a5,a3,80003ffc <write_head+0x4e>
  }
  bwrite(buf);
    80004008:	8526                	mv	a0,s1
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	09c080e7          	jalr	156(ra) # 800030a6 <bwrite>
  brelse(buf);
    80004012:	8526                	mv	a0,s1
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	0d0080e7          	jalr	208(ra) # 800030e4 <brelse>
}
    8000401c:	60e2                	ld	ra,24(sp)
    8000401e:	6442                	ld	s0,16(sp)
    80004020:	64a2                	ld	s1,8(sp)
    80004022:	6902                	ld	s2,0(sp)
    80004024:	6105                	addi	sp,sp,32
    80004026:	8082                	ret

0000000080004028 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004028:	0001d797          	auipc	a5,0x1d
    8000402c:	f947a783          	lw	a5,-108(a5) # 80020fbc <log+0x2c>
    80004030:	0af05d63          	blez	a5,800040ea <install_trans+0xc2>
{
    80004034:	7139                	addi	sp,sp,-64
    80004036:	fc06                	sd	ra,56(sp)
    80004038:	f822                	sd	s0,48(sp)
    8000403a:	f426                	sd	s1,40(sp)
    8000403c:	f04a                	sd	s2,32(sp)
    8000403e:	ec4e                	sd	s3,24(sp)
    80004040:	e852                	sd	s4,16(sp)
    80004042:	e456                	sd	s5,8(sp)
    80004044:	e05a                	sd	s6,0(sp)
    80004046:	0080                	addi	s0,sp,64
    80004048:	8b2a                	mv	s6,a0
    8000404a:	0001da97          	auipc	s5,0x1d
    8000404e:	f76a8a93          	addi	s5,s5,-138 # 80020fc0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004052:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004054:	0001d997          	auipc	s3,0x1d
    80004058:	f3c98993          	addi	s3,s3,-196 # 80020f90 <log>
    8000405c:	a035                	j	80004088 <install_trans+0x60>
      bunpin(dbuf);
    8000405e:	8526                	mv	a0,s1
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	15e080e7          	jalr	350(ra) # 800031be <bunpin>
    brelse(lbuf);
    80004068:	854a                	mv	a0,s2
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	07a080e7          	jalr	122(ra) # 800030e4 <brelse>
    brelse(dbuf);
    80004072:	8526                	mv	a0,s1
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	070080e7          	jalr	112(ra) # 800030e4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000407c:	2a05                	addiw	s4,s4,1
    8000407e:	0a91                	addi	s5,s5,4
    80004080:	02c9a783          	lw	a5,44(s3)
    80004084:	04fa5963          	bge	s4,a5,800040d6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004088:	0189a583          	lw	a1,24(s3)
    8000408c:	014585bb          	addw	a1,a1,s4
    80004090:	2585                	addiw	a1,a1,1
    80004092:	0289a503          	lw	a0,40(s3)
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	f1e080e7          	jalr	-226(ra) # 80002fb4 <bread>
    8000409e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040a0:	000aa583          	lw	a1,0(s5)
    800040a4:	0289a503          	lw	a0,40(s3)
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	f0c080e7          	jalr	-244(ra) # 80002fb4 <bread>
    800040b0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040b2:	40000613          	li	a2,1024
    800040b6:	05890593          	addi	a1,s2,88
    800040ba:	05850513          	addi	a0,a0,88
    800040be:	ffffd097          	auipc	ra,0xffffd
    800040c2:	c88080e7          	jalr	-888(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040c6:	8526                	mv	a0,s1
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	fde080e7          	jalr	-34(ra) # 800030a6 <bwrite>
    if(recovering == 0)
    800040d0:	f80b1ce3          	bnez	s6,80004068 <install_trans+0x40>
    800040d4:	b769                	j	8000405e <install_trans+0x36>
}
    800040d6:	70e2                	ld	ra,56(sp)
    800040d8:	7442                	ld	s0,48(sp)
    800040da:	74a2                	ld	s1,40(sp)
    800040dc:	7902                	ld	s2,32(sp)
    800040de:	69e2                	ld	s3,24(sp)
    800040e0:	6a42                	ld	s4,16(sp)
    800040e2:	6aa2                	ld	s5,8(sp)
    800040e4:	6b02                	ld	s6,0(sp)
    800040e6:	6121                	addi	sp,sp,64
    800040e8:	8082                	ret
    800040ea:	8082                	ret

00000000800040ec <initlog>:
{
    800040ec:	7179                	addi	sp,sp,-48
    800040ee:	f406                	sd	ra,40(sp)
    800040f0:	f022                	sd	s0,32(sp)
    800040f2:	ec26                	sd	s1,24(sp)
    800040f4:	e84a                	sd	s2,16(sp)
    800040f6:	e44e                	sd	s3,8(sp)
    800040f8:	1800                	addi	s0,sp,48
    800040fa:	892a                	mv	s2,a0
    800040fc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040fe:	0001d497          	auipc	s1,0x1d
    80004102:	e9248493          	addi	s1,s1,-366 # 80020f90 <log>
    80004106:	00004597          	auipc	a1,0x4
    8000410a:	58a58593          	addi	a1,a1,1418 # 80008690 <syscalls+0x1e8>
    8000410e:	8526                	mv	a0,s1
    80004110:	ffffd097          	auipc	ra,0xffffd
    80004114:	a4a080e7          	jalr	-1462(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004118:	0149a583          	lw	a1,20(s3)
    8000411c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000411e:	0109a783          	lw	a5,16(s3)
    80004122:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004124:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004128:	854a                	mv	a0,s2
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	e8a080e7          	jalr	-374(ra) # 80002fb4 <bread>
  log.lh.n = lh->n;
    80004132:	4d3c                	lw	a5,88(a0)
    80004134:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004136:	02f05563          	blez	a5,80004160 <initlog+0x74>
    8000413a:	05c50713          	addi	a4,a0,92
    8000413e:	0001d697          	auipc	a3,0x1d
    80004142:	e8268693          	addi	a3,a3,-382 # 80020fc0 <log+0x30>
    80004146:	37fd                	addiw	a5,a5,-1
    80004148:	1782                	slli	a5,a5,0x20
    8000414a:	9381                	srli	a5,a5,0x20
    8000414c:	078a                	slli	a5,a5,0x2
    8000414e:	06050613          	addi	a2,a0,96
    80004152:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004154:	4310                	lw	a2,0(a4)
    80004156:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004158:	0711                	addi	a4,a4,4
    8000415a:	0691                	addi	a3,a3,4
    8000415c:	fef71ce3          	bne	a4,a5,80004154 <initlog+0x68>
  brelse(buf);
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	f84080e7          	jalr	-124(ra) # 800030e4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004168:	4505                	li	a0,1
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	ebe080e7          	jalr	-322(ra) # 80004028 <install_trans>
  log.lh.n = 0;
    80004172:	0001d797          	auipc	a5,0x1d
    80004176:	e407a523          	sw	zero,-438(a5) # 80020fbc <log+0x2c>
  write_head(); // clear the log
    8000417a:	00000097          	auipc	ra,0x0
    8000417e:	e34080e7          	jalr	-460(ra) # 80003fae <write_head>
}
    80004182:	70a2                	ld	ra,40(sp)
    80004184:	7402                	ld	s0,32(sp)
    80004186:	64e2                	ld	s1,24(sp)
    80004188:	6942                	ld	s2,16(sp)
    8000418a:	69a2                	ld	s3,8(sp)
    8000418c:	6145                	addi	sp,sp,48
    8000418e:	8082                	ret

0000000080004190 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004190:	1101                	addi	sp,sp,-32
    80004192:	ec06                	sd	ra,24(sp)
    80004194:	e822                	sd	s0,16(sp)
    80004196:	e426                	sd	s1,8(sp)
    80004198:	e04a                	sd	s2,0(sp)
    8000419a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000419c:	0001d517          	auipc	a0,0x1d
    800041a0:	df450513          	addi	a0,a0,-524 # 80020f90 <log>
    800041a4:	ffffd097          	auipc	ra,0xffffd
    800041a8:	a46080e7          	jalr	-1466(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    800041ac:	0001d497          	auipc	s1,0x1d
    800041b0:	de448493          	addi	s1,s1,-540 # 80020f90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b4:	4979                	li	s2,30
    800041b6:	a039                	j	800041c4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041b8:	85a6                	mv	a1,s1
    800041ba:	8526                	mv	a0,s1
    800041bc:	ffffe097          	auipc	ra,0xffffe
    800041c0:	f26080e7          	jalr	-218(ra) # 800020e2 <sleep>
    if(log.committing){
    800041c4:	50dc                	lw	a5,36(s1)
    800041c6:	fbed                	bnez	a5,800041b8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041c8:	509c                	lw	a5,32(s1)
    800041ca:	0017871b          	addiw	a4,a5,1
    800041ce:	0007069b          	sext.w	a3,a4
    800041d2:	0027179b          	slliw	a5,a4,0x2
    800041d6:	9fb9                	addw	a5,a5,a4
    800041d8:	0017979b          	slliw	a5,a5,0x1
    800041dc:	54d8                	lw	a4,44(s1)
    800041de:	9fb9                	addw	a5,a5,a4
    800041e0:	00f95963          	bge	s2,a5,800041f2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041e4:	85a6                	mv	a1,s1
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffe097          	auipc	ra,0xffffe
    800041ec:	efa080e7          	jalr	-262(ra) # 800020e2 <sleep>
    800041f0:	bfd1                	j	800041c4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041f2:	0001d517          	auipc	a0,0x1d
    800041f6:	d9e50513          	addi	a0,a0,-610 # 80020f90 <log>
    800041fa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041fc:	ffffd097          	auipc	ra,0xffffd
    80004200:	aa2080e7          	jalr	-1374(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004204:	60e2                	ld	ra,24(sp)
    80004206:	6442                	ld	s0,16(sp)
    80004208:	64a2                	ld	s1,8(sp)
    8000420a:	6902                	ld	s2,0(sp)
    8000420c:	6105                	addi	sp,sp,32
    8000420e:	8082                	ret

0000000080004210 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004210:	7139                	addi	sp,sp,-64
    80004212:	fc06                	sd	ra,56(sp)
    80004214:	f822                	sd	s0,48(sp)
    80004216:	f426                	sd	s1,40(sp)
    80004218:	f04a                	sd	s2,32(sp)
    8000421a:	ec4e                	sd	s3,24(sp)
    8000421c:	e852                	sd	s4,16(sp)
    8000421e:	e456                	sd	s5,8(sp)
    80004220:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004222:	0001d497          	auipc	s1,0x1d
    80004226:	d6e48493          	addi	s1,s1,-658 # 80020f90 <log>
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	9be080e7          	jalr	-1602(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004234:	509c                	lw	a5,32(s1)
    80004236:	37fd                	addiw	a5,a5,-1
    80004238:	0007891b          	sext.w	s2,a5
    8000423c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000423e:	50dc                	lw	a5,36(s1)
    80004240:	efb9                	bnez	a5,8000429e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004242:	06091663          	bnez	s2,800042ae <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004246:	0001d497          	auipc	s1,0x1d
    8000424a:	d4a48493          	addi	s1,s1,-694 # 80020f90 <log>
    8000424e:	4785                	li	a5,1
    80004250:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004252:	8526                	mv	a0,s1
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	a4a080e7          	jalr	-1462(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000425c:	54dc                	lw	a5,44(s1)
    8000425e:	06f04763          	bgtz	a5,800042cc <end_op+0xbc>
    acquire(&log.lock);
    80004262:	0001d497          	auipc	s1,0x1d
    80004266:	d2e48493          	addi	s1,s1,-722 # 80020f90 <log>
    8000426a:	8526                	mv	a0,s1
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	97e080e7          	jalr	-1666(ra) # 80000bea <acquire>
    log.committing = 0;
    80004274:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004278:	8526                	mv	a0,s1
    8000427a:	ffffe097          	auipc	ra,0xffffe
    8000427e:	ecc080e7          	jalr	-308(ra) # 80002146 <wakeup>
    release(&log.lock);
    80004282:	8526                	mv	a0,s1
    80004284:	ffffd097          	auipc	ra,0xffffd
    80004288:	a1a080e7          	jalr	-1510(ra) # 80000c9e <release>
}
    8000428c:	70e2                	ld	ra,56(sp)
    8000428e:	7442                	ld	s0,48(sp)
    80004290:	74a2                	ld	s1,40(sp)
    80004292:	7902                	ld	s2,32(sp)
    80004294:	69e2                	ld	s3,24(sp)
    80004296:	6a42                	ld	s4,16(sp)
    80004298:	6aa2                	ld	s5,8(sp)
    8000429a:	6121                	addi	sp,sp,64
    8000429c:	8082                	ret
    panic("log.committing");
    8000429e:	00004517          	auipc	a0,0x4
    800042a2:	3fa50513          	addi	a0,a0,1018 # 80008698 <syscalls+0x1f0>
    800042a6:	ffffc097          	auipc	ra,0xffffc
    800042aa:	29e080e7          	jalr	670(ra) # 80000544 <panic>
    wakeup(&log);
    800042ae:	0001d497          	auipc	s1,0x1d
    800042b2:	ce248493          	addi	s1,s1,-798 # 80020f90 <log>
    800042b6:	8526                	mv	a0,s1
    800042b8:	ffffe097          	auipc	ra,0xffffe
    800042bc:	e8e080e7          	jalr	-370(ra) # 80002146 <wakeup>
  release(&log.lock);
    800042c0:	8526                	mv	a0,s1
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	9dc080e7          	jalr	-1572(ra) # 80000c9e <release>
  if(do_commit){
    800042ca:	b7c9                	j	8000428c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042cc:	0001da97          	auipc	s5,0x1d
    800042d0:	cf4a8a93          	addi	s5,s5,-780 # 80020fc0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042d4:	0001da17          	auipc	s4,0x1d
    800042d8:	cbca0a13          	addi	s4,s4,-836 # 80020f90 <log>
    800042dc:	018a2583          	lw	a1,24(s4)
    800042e0:	012585bb          	addw	a1,a1,s2
    800042e4:	2585                	addiw	a1,a1,1
    800042e6:	028a2503          	lw	a0,40(s4)
    800042ea:	fffff097          	auipc	ra,0xfffff
    800042ee:	cca080e7          	jalr	-822(ra) # 80002fb4 <bread>
    800042f2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042f4:	000aa583          	lw	a1,0(s5)
    800042f8:	028a2503          	lw	a0,40(s4)
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	cb8080e7          	jalr	-840(ra) # 80002fb4 <bread>
    80004304:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004306:	40000613          	li	a2,1024
    8000430a:	05850593          	addi	a1,a0,88
    8000430e:	05848513          	addi	a0,s1,88
    80004312:	ffffd097          	auipc	ra,0xffffd
    80004316:	a34080e7          	jalr	-1484(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    8000431a:	8526                	mv	a0,s1
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	d8a080e7          	jalr	-630(ra) # 800030a6 <bwrite>
    brelse(from);
    80004324:	854e                	mv	a0,s3
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	dbe080e7          	jalr	-578(ra) # 800030e4 <brelse>
    brelse(to);
    8000432e:	8526                	mv	a0,s1
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	db4080e7          	jalr	-588(ra) # 800030e4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004338:	2905                	addiw	s2,s2,1
    8000433a:	0a91                	addi	s5,s5,4
    8000433c:	02ca2783          	lw	a5,44(s4)
    80004340:	f8f94ee3          	blt	s2,a5,800042dc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004344:	00000097          	auipc	ra,0x0
    80004348:	c6a080e7          	jalr	-918(ra) # 80003fae <write_head>
    install_trans(0); // Now install writes to home locations
    8000434c:	4501                	li	a0,0
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	cda080e7          	jalr	-806(ra) # 80004028 <install_trans>
    log.lh.n = 0;
    80004356:	0001d797          	auipc	a5,0x1d
    8000435a:	c607a323          	sw	zero,-922(a5) # 80020fbc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	c50080e7          	jalr	-944(ra) # 80003fae <write_head>
    80004366:	bdf5                	j	80004262 <end_op+0x52>

0000000080004368 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004368:	1101                	addi	sp,sp,-32
    8000436a:	ec06                	sd	ra,24(sp)
    8000436c:	e822                	sd	s0,16(sp)
    8000436e:	e426                	sd	s1,8(sp)
    80004370:	e04a                	sd	s2,0(sp)
    80004372:	1000                	addi	s0,sp,32
    80004374:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004376:	0001d917          	auipc	s2,0x1d
    8000437a:	c1a90913          	addi	s2,s2,-998 # 80020f90 <log>
    8000437e:	854a                	mv	a0,s2
    80004380:	ffffd097          	auipc	ra,0xffffd
    80004384:	86a080e7          	jalr	-1942(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004388:	02c92603          	lw	a2,44(s2)
    8000438c:	47f5                	li	a5,29
    8000438e:	06c7c563          	blt	a5,a2,800043f8 <log_write+0x90>
    80004392:	0001d797          	auipc	a5,0x1d
    80004396:	c1a7a783          	lw	a5,-998(a5) # 80020fac <log+0x1c>
    8000439a:	37fd                	addiw	a5,a5,-1
    8000439c:	04f65e63          	bge	a2,a5,800043f8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043a0:	0001d797          	auipc	a5,0x1d
    800043a4:	c107a783          	lw	a5,-1008(a5) # 80020fb0 <log+0x20>
    800043a8:	06f05063          	blez	a5,80004408 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043ac:	4781                	li	a5,0
    800043ae:	06c05563          	blez	a2,80004418 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043b2:	44cc                	lw	a1,12(s1)
    800043b4:	0001d717          	auipc	a4,0x1d
    800043b8:	c0c70713          	addi	a4,a4,-1012 # 80020fc0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043bc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043be:	4314                	lw	a3,0(a4)
    800043c0:	04b68c63          	beq	a3,a1,80004418 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043c4:	2785                	addiw	a5,a5,1
    800043c6:	0711                	addi	a4,a4,4
    800043c8:	fef61be3          	bne	a2,a5,800043be <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043cc:	0621                	addi	a2,a2,8
    800043ce:	060a                	slli	a2,a2,0x2
    800043d0:	0001d797          	auipc	a5,0x1d
    800043d4:	bc078793          	addi	a5,a5,-1088 # 80020f90 <log>
    800043d8:	963e                	add	a2,a2,a5
    800043da:	44dc                	lw	a5,12(s1)
    800043dc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043de:	8526                	mv	a0,s1
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	da2080e7          	jalr	-606(ra) # 80003182 <bpin>
    log.lh.n++;
    800043e8:	0001d717          	auipc	a4,0x1d
    800043ec:	ba870713          	addi	a4,a4,-1112 # 80020f90 <log>
    800043f0:	575c                	lw	a5,44(a4)
    800043f2:	2785                	addiw	a5,a5,1
    800043f4:	d75c                	sw	a5,44(a4)
    800043f6:	a835                	j	80004432 <log_write+0xca>
    panic("too big a transaction");
    800043f8:	00004517          	auipc	a0,0x4
    800043fc:	2b050513          	addi	a0,a0,688 # 800086a8 <syscalls+0x200>
    80004400:	ffffc097          	auipc	ra,0xffffc
    80004404:	144080e7          	jalr	324(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004408:	00004517          	auipc	a0,0x4
    8000440c:	2b850513          	addi	a0,a0,696 # 800086c0 <syscalls+0x218>
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	134080e7          	jalr	308(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004418:	00878713          	addi	a4,a5,8
    8000441c:	00271693          	slli	a3,a4,0x2
    80004420:	0001d717          	auipc	a4,0x1d
    80004424:	b7070713          	addi	a4,a4,-1168 # 80020f90 <log>
    80004428:	9736                	add	a4,a4,a3
    8000442a:	44d4                	lw	a3,12(s1)
    8000442c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000442e:	faf608e3          	beq	a2,a5,800043de <log_write+0x76>
  }
  release(&log.lock);
    80004432:	0001d517          	auipc	a0,0x1d
    80004436:	b5e50513          	addi	a0,a0,-1186 # 80020f90 <log>
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	864080e7          	jalr	-1948(ra) # 80000c9e <release>
}
    80004442:	60e2                	ld	ra,24(sp)
    80004444:	6442                	ld	s0,16(sp)
    80004446:	64a2                	ld	s1,8(sp)
    80004448:	6902                	ld	s2,0(sp)
    8000444a:	6105                	addi	sp,sp,32
    8000444c:	8082                	ret

000000008000444e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000444e:	1101                	addi	sp,sp,-32
    80004450:	ec06                	sd	ra,24(sp)
    80004452:	e822                	sd	s0,16(sp)
    80004454:	e426                	sd	s1,8(sp)
    80004456:	e04a                	sd	s2,0(sp)
    80004458:	1000                	addi	s0,sp,32
    8000445a:	84aa                	mv	s1,a0
    8000445c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000445e:	00004597          	auipc	a1,0x4
    80004462:	28258593          	addi	a1,a1,642 # 800086e0 <syscalls+0x238>
    80004466:	0521                	addi	a0,a0,8
    80004468:	ffffc097          	auipc	ra,0xffffc
    8000446c:	6f2080e7          	jalr	1778(ra) # 80000b5a <initlock>
  lk->name = name;
    80004470:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004474:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004478:	0204a423          	sw	zero,40(s1)
}
    8000447c:	60e2                	ld	ra,24(sp)
    8000447e:	6442                	ld	s0,16(sp)
    80004480:	64a2                	ld	s1,8(sp)
    80004482:	6902                	ld	s2,0(sp)
    80004484:	6105                	addi	sp,sp,32
    80004486:	8082                	ret

0000000080004488 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004488:	1101                	addi	sp,sp,-32
    8000448a:	ec06                	sd	ra,24(sp)
    8000448c:	e822                	sd	s0,16(sp)
    8000448e:	e426                	sd	s1,8(sp)
    80004490:	e04a                	sd	s2,0(sp)
    80004492:	1000                	addi	s0,sp,32
    80004494:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004496:	00850913          	addi	s2,a0,8
    8000449a:	854a                	mv	a0,s2
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	74e080e7          	jalr	1870(ra) # 80000bea <acquire>
  while (lk->locked) {
    800044a4:	409c                	lw	a5,0(s1)
    800044a6:	cb89                	beqz	a5,800044b8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044a8:	85ca                	mv	a1,s2
    800044aa:	8526                	mv	a0,s1
    800044ac:	ffffe097          	auipc	ra,0xffffe
    800044b0:	c36080e7          	jalr	-970(ra) # 800020e2 <sleep>
  while (lk->locked) {
    800044b4:	409c                	lw	a5,0(s1)
    800044b6:	fbed                	bnez	a5,800044a8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044b8:	4785                	li	a5,1
    800044ba:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044bc:	ffffd097          	auipc	ra,0xffffd
    800044c0:	50a080e7          	jalr	1290(ra) # 800019c6 <myproc>
    800044c4:	591c                	lw	a5,48(a0)
    800044c6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044c8:	854a                	mv	a0,s2
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	7d4080e7          	jalr	2004(ra) # 80000c9e <release>
}
    800044d2:	60e2                	ld	ra,24(sp)
    800044d4:	6442                	ld	s0,16(sp)
    800044d6:	64a2                	ld	s1,8(sp)
    800044d8:	6902                	ld	s2,0(sp)
    800044da:	6105                	addi	sp,sp,32
    800044dc:	8082                	ret

00000000800044de <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044de:	1101                	addi	sp,sp,-32
    800044e0:	ec06                	sd	ra,24(sp)
    800044e2:	e822                	sd	s0,16(sp)
    800044e4:	e426                	sd	s1,8(sp)
    800044e6:	e04a                	sd	s2,0(sp)
    800044e8:	1000                	addi	s0,sp,32
    800044ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ec:	00850913          	addi	s2,a0,8
    800044f0:	854a                	mv	a0,s2
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	6f8080e7          	jalr	1784(ra) # 80000bea <acquire>
  lk->locked = 0;
    800044fa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fe:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004502:	8526                	mv	a0,s1
    80004504:	ffffe097          	auipc	ra,0xffffe
    80004508:	c42080e7          	jalr	-958(ra) # 80002146 <wakeup>
  release(&lk->lk);
    8000450c:	854a                	mv	a0,s2
    8000450e:	ffffc097          	auipc	ra,0xffffc
    80004512:	790080e7          	jalr	1936(ra) # 80000c9e <release>
}
    80004516:	60e2                	ld	ra,24(sp)
    80004518:	6442                	ld	s0,16(sp)
    8000451a:	64a2                	ld	s1,8(sp)
    8000451c:	6902                	ld	s2,0(sp)
    8000451e:	6105                	addi	sp,sp,32
    80004520:	8082                	ret

0000000080004522 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004522:	7179                	addi	sp,sp,-48
    80004524:	f406                	sd	ra,40(sp)
    80004526:	f022                	sd	s0,32(sp)
    80004528:	ec26                	sd	s1,24(sp)
    8000452a:	e84a                	sd	s2,16(sp)
    8000452c:	e44e                	sd	s3,8(sp)
    8000452e:	1800                	addi	s0,sp,48
    80004530:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004532:	00850913          	addi	s2,a0,8
    80004536:	854a                	mv	a0,s2
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	6b2080e7          	jalr	1714(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004540:	409c                	lw	a5,0(s1)
    80004542:	ef99                	bnez	a5,80004560 <holdingsleep+0x3e>
    80004544:	4481                	li	s1,0
  release(&lk->lk);
    80004546:	854a                	mv	a0,s2
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	756080e7          	jalr	1878(ra) # 80000c9e <release>
  return r;
}
    80004550:	8526                	mv	a0,s1
    80004552:	70a2                	ld	ra,40(sp)
    80004554:	7402                	ld	s0,32(sp)
    80004556:	64e2                	ld	s1,24(sp)
    80004558:	6942                	ld	s2,16(sp)
    8000455a:	69a2                	ld	s3,8(sp)
    8000455c:	6145                	addi	sp,sp,48
    8000455e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004560:	0284a983          	lw	s3,40(s1)
    80004564:	ffffd097          	auipc	ra,0xffffd
    80004568:	462080e7          	jalr	1122(ra) # 800019c6 <myproc>
    8000456c:	5904                	lw	s1,48(a0)
    8000456e:	413484b3          	sub	s1,s1,s3
    80004572:	0014b493          	seqz	s1,s1
    80004576:	bfc1                	j	80004546 <holdingsleep+0x24>

0000000080004578 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004578:	1141                	addi	sp,sp,-16
    8000457a:	e406                	sd	ra,8(sp)
    8000457c:	e022                	sd	s0,0(sp)
    8000457e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004580:	00004597          	auipc	a1,0x4
    80004584:	17058593          	addi	a1,a1,368 # 800086f0 <syscalls+0x248>
    80004588:	0001d517          	auipc	a0,0x1d
    8000458c:	b5050513          	addi	a0,a0,-1200 # 800210d8 <ftable>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	5ca080e7          	jalr	1482(ra) # 80000b5a <initlock>
}
    80004598:	60a2                	ld	ra,8(sp)
    8000459a:	6402                	ld	s0,0(sp)
    8000459c:	0141                	addi	sp,sp,16
    8000459e:	8082                	ret

00000000800045a0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045a0:	1101                	addi	sp,sp,-32
    800045a2:	ec06                	sd	ra,24(sp)
    800045a4:	e822                	sd	s0,16(sp)
    800045a6:	e426                	sd	s1,8(sp)
    800045a8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045aa:	0001d517          	auipc	a0,0x1d
    800045ae:	b2e50513          	addi	a0,a0,-1234 # 800210d8 <ftable>
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	638080e7          	jalr	1592(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ba:	0001d497          	auipc	s1,0x1d
    800045be:	b3648493          	addi	s1,s1,-1226 # 800210f0 <ftable+0x18>
    800045c2:	0001e717          	auipc	a4,0x1e
    800045c6:	ace70713          	addi	a4,a4,-1330 # 80022090 <disk>
    if(f->ref == 0){
    800045ca:	40dc                	lw	a5,4(s1)
    800045cc:	cf99                	beqz	a5,800045ea <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ce:	02848493          	addi	s1,s1,40
    800045d2:	fee49ce3          	bne	s1,a4,800045ca <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045d6:	0001d517          	auipc	a0,0x1d
    800045da:	b0250513          	addi	a0,a0,-1278 # 800210d8 <ftable>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	6c0080e7          	jalr	1728(ra) # 80000c9e <release>
  return 0;
    800045e6:	4481                	li	s1,0
    800045e8:	a819                	j	800045fe <filealloc+0x5e>
      f->ref = 1;
    800045ea:	4785                	li	a5,1
    800045ec:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ee:	0001d517          	auipc	a0,0x1d
    800045f2:	aea50513          	addi	a0,a0,-1302 # 800210d8 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	6a8080e7          	jalr	1704(ra) # 80000c9e <release>
}
    800045fe:	8526                	mv	a0,s1
    80004600:	60e2                	ld	ra,24(sp)
    80004602:	6442                	ld	s0,16(sp)
    80004604:	64a2                	ld	s1,8(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret

000000008000460a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000460a:	1101                	addi	sp,sp,-32
    8000460c:	ec06                	sd	ra,24(sp)
    8000460e:	e822                	sd	s0,16(sp)
    80004610:	e426                	sd	s1,8(sp)
    80004612:	1000                	addi	s0,sp,32
    80004614:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004616:	0001d517          	auipc	a0,0x1d
    8000461a:	ac250513          	addi	a0,a0,-1342 # 800210d8 <ftable>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	5cc080e7          	jalr	1484(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004626:	40dc                	lw	a5,4(s1)
    80004628:	02f05263          	blez	a5,8000464c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000462c:	2785                	addiw	a5,a5,1
    8000462e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004630:	0001d517          	auipc	a0,0x1d
    80004634:	aa850513          	addi	a0,a0,-1368 # 800210d8 <ftable>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	666080e7          	jalr	1638(ra) # 80000c9e <release>
  return f;
}
    80004640:	8526                	mv	a0,s1
    80004642:	60e2                	ld	ra,24(sp)
    80004644:	6442                	ld	s0,16(sp)
    80004646:	64a2                	ld	s1,8(sp)
    80004648:	6105                	addi	sp,sp,32
    8000464a:	8082                	ret
    panic("filedup");
    8000464c:	00004517          	auipc	a0,0x4
    80004650:	0ac50513          	addi	a0,a0,172 # 800086f8 <syscalls+0x250>
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	ef0080e7          	jalr	-272(ra) # 80000544 <panic>

000000008000465c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000465c:	7139                	addi	sp,sp,-64
    8000465e:	fc06                	sd	ra,56(sp)
    80004660:	f822                	sd	s0,48(sp)
    80004662:	f426                	sd	s1,40(sp)
    80004664:	f04a                	sd	s2,32(sp)
    80004666:	ec4e                	sd	s3,24(sp)
    80004668:	e852                	sd	s4,16(sp)
    8000466a:	e456                	sd	s5,8(sp)
    8000466c:	0080                	addi	s0,sp,64
    8000466e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004670:	0001d517          	auipc	a0,0x1d
    80004674:	a6850513          	addi	a0,a0,-1432 # 800210d8 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	572080e7          	jalr	1394(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004680:	40dc                	lw	a5,4(s1)
    80004682:	06f05163          	blez	a5,800046e4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004686:	37fd                	addiw	a5,a5,-1
    80004688:	0007871b          	sext.w	a4,a5
    8000468c:	c0dc                	sw	a5,4(s1)
    8000468e:	06e04363          	bgtz	a4,800046f4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004692:	0004a903          	lw	s2,0(s1)
    80004696:	0094ca83          	lbu	s5,9(s1)
    8000469a:	0104ba03          	ld	s4,16(s1)
    8000469e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046a2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046a6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046aa:	0001d517          	auipc	a0,0x1d
    800046ae:	a2e50513          	addi	a0,a0,-1490 # 800210d8 <ftable>
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	5ec080e7          	jalr	1516(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800046ba:	4785                	li	a5,1
    800046bc:	04f90d63          	beq	s2,a5,80004716 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046c0:	3979                	addiw	s2,s2,-2
    800046c2:	4785                	li	a5,1
    800046c4:	0527e063          	bltu	a5,s2,80004704 <fileclose+0xa8>
    begin_op();
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	ac8080e7          	jalr	-1336(ra) # 80004190 <begin_op>
    iput(ff.ip);
    800046d0:	854e                	mv	a0,s3
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	2b6080e7          	jalr	694(ra) # 80003988 <iput>
    end_op();
    800046da:	00000097          	auipc	ra,0x0
    800046de:	b36080e7          	jalr	-1226(ra) # 80004210 <end_op>
    800046e2:	a00d                	j	80004704 <fileclose+0xa8>
    panic("fileclose");
    800046e4:	00004517          	auipc	a0,0x4
    800046e8:	01c50513          	addi	a0,a0,28 # 80008700 <syscalls+0x258>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	e58080e7          	jalr	-424(ra) # 80000544 <panic>
    release(&ftable.lock);
    800046f4:	0001d517          	auipc	a0,0x1d
    800046f8:	9e450513          	addi	a0,a0,-1564 # 800210d8 <ftable>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	5a2080e7          	jalr	1442(ra) # 80000c9e <release>
  }
}
    80004704:	70e2                	ld	ra,56(sp)
    80004706:	7442                	ld	s0,48(sp)
    80004708:	74a2                	ld	s1,40(sp)
    8000470a:	7902                	ld	s2,32(sp)
    8000470c:	69e2                	ld	s3,24(sp)
    8000470e:	6a42                	ld	s4,16(sp)
    80004710:	6aa2                	ld	s5,8(sp)
    80004712:	6121                	addi	sp,sp,64
    80004714:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004716:	85d6                	mv	a1,s5
    80004718:	8552                	mv	a0,s4
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	34c080e7          	jalr	844(ra) # 80004a66 <pipeclose>
    80004722:	b7cd                	j	80004704 <fileclose+0xa8>

0000000080004724 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004724:	715d                	addi	sp,sp,-80
    80004726:	e486                	sd	ra,72(sp)
    80004728:	e0a2                	sd	s0,64(sp)
    8000472a:	fc26                	sd	s1,56(sp)
    8000472c:	f84a                	sd	s2,48(sp)
    8000472e:	f44e                	sd	s3,40(sp)
    80004730:	0880                	addi	s0,sp,80
    80004732:	84aa                	mv	s1,a0
    80004734:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004736:	ffffd097          	auipc	ra,0xffffd
    8000473a:	290080e7          	jalr	656(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000473e:	409c                	lw	a5,0(s1)
    80004740:	37f9                	addiw	a5,a5,-2
    80004742:	4705                	li	a4,1
    80004744:	04f76763          	bltu	a4,a5,80004792 <filestat+0x6e>
    80004748:	892a                	mv	s2,a0
    ilock(f->ip);
    8000474a:	6c88                	ld	a0,24(s1)
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	082080e7          	jalr	130(ra) # 800037ce <ilock>
    stati(f->ip, &st);
    80004754:	fb840593          	addi	a1,s0,-72
    80004758:	6c88                	ld	a0,24(s1)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	2fe080e7          	jalr	766(ra) # 80003a58 <stati>
    iunlock(f->ip);
    80004762:	6c88                	ld	a0,24(s1)
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	12c080e7          	jalr	300(ra) # 80003890 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000476c:	46e1                	li	a3,24
    8000476e:	fb840613          	addi	a2,s0,-72
    80004772:	85ce                	mv	a1,s3
    80004774:	06093503          	ld	a0,96(s2)
    80004778:	ffffd097          	auipc	ra,0xffffd
    8000477c:	f0c080e7          	jalr	-244(ra) # 80001684 <copyout>
    80004780:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004784:	60a6                	ld	ra,72(sp)
    80004786:	6406                	ld	s0,64(sp)
    80004788:	74e2                	ld	s1,56(sp)
    8000478a:	7942                	ld	s2,48(sp)
    8000478c:	79a2                	ld	s3,40(sp)
    8000478e:	6161                	addi	sp,sp,80
    80004790:	8082                	ret
  return -1;
    80004792:	557d                	li	a0,-1
    80004794:	bfc5                	j	80004784 <filestat+0x60>

0000000080004796 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004796:	7179                	addi	sp,sp,-48
    80004798:	f406                	sd	ra,40(sp)
    8000479a:	f022                	sd	s0,32(sp)
    8000479c:	ec26                	sd	s1,24(sp)
    8000479e:	e84a                	sd	s2,16(sp)
    800047a0:	e44e                	sd	s3,8(sp)
    800047a2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047a4:	00854783          	lbu	a5,8(a0)
    800047a8:	c3d5                	beqz	a5,8000484c <fileread+0xb6>
    800047aa:	84aa                	mv	s1,a0
    800047ac:	89ae                	mv	s3,a1
    800047ae:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047b0:	411c                	lw	a5,0(a0)
    800047b2:	4705                	li	a4,1
    800047b4:	04e78963          	beq	a5,a4,80004806 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047b8:	470d                	li	a4,3
    800047ba:	04e78d63          	beq	a5,a4,80004814 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047be:	4709                	li	a4,2
    800047c0:	06e79e63          	bne	a5,a4,8000483c <fileread+0xa6>
    ilock(f->ip);
    800047c4:	6d08                	ld	a0,24(a0)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	008080e7          	jalr	8(ra) # 800037ce <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ce:	874a                	mv	a4,s2
    800047d0:	5094                	lw	a3,32(s1)
    800047d2:	864e                	mv	a2,s3
    800047d4:	4585                	li	a1,1
    800047d6:	6c88                	ld	a0,24(s1)
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	2aa080e7          	jalr	682(ra) # 80003a82 <readi>
    800047e0:	892a                	mv	s2,a0
    800047e2:	00a05563          	blez	a0,800047ec <fileread+0x56>
      f->off += r;
    800047e6:	509c                	lw	a5,32(s1)
    800047e8:	9fa9                	addw	a5,a5,a0
    800047ea:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ec:	6c88                	ld	a0,24(s1)
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	0a2080e7          	jalr	162(ra) # 80003890 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047f6:	854a                	mv	a0,s2
    800047f8:	70a2                	ld	ra,40(sp)
    800047fa:	7402                	ld	s0,32(sp)
    800047fc:	64e2                	ld	s1,24(sp)
    800047fe:	6942                	ld	s2,16(sp)
    80004800:	69a2                	ld	s3,8(sp)
    80004802:	6145                	addi	sp,sp,48
    80004804:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004806:	6908                	ld	a0,16(a0)
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	3ce080e7          	jalr	974(ra) # 80004bd6 <piperead>
    80004810:	892a                	mv	s2,a0
    80004812:	b7d5                	j	800047f6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004814:	02451783          	lh	a5,36(a0)
    80004818:	03079693          	slli	a3,a5,0x30
    8000481c:	92c1                	srli	a3,a3,0x30
    8000481e:	4725                	li	a4,9
    80004820:	02d76863          	bltu	a4,a3,80004850 <fileread+0xba>
    80004824:	0792                	slli	a5,a5,0x4
    80004826:	0001d717          	auipc	a4,0x1d
    8000482a:	81270713          	addi	a4,a4,-2030 # 80021038 <devsw>
    8000482e:	97ba                	add	a5,a5,a4
    80004830:	639c                	ld	a5,0(a5)
    80004832:	c38d                	beqz	a5,80004854 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004834:	4505                	li	a0,1
    80004836:	9782                	jalr	a5
    80004838:	892a                	mv	s2,a0
    8000483a:	bf75                	j	800047f6 <fileread+0x60>
    panic("fileread");
    8000483c:	00004517          	auipc	a0,0x4
    80004840:	ed450513          	addi	a0,a0,-300 # 80008710 <syscalls+0x268>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	d00080e7          	jalr	-768(ra) # 80000544 <panic>
    return -1;
    8000484c:	597d                	li	s2,-1
    8000484e:	b765                	j	800047f6 <fileread+0x60>
      return -1;
    80004850:	597d                	li	s2,-1
    80004852:	b755                	j	800047f6 <fileread+0x60>
    80004854:	597d                	li	s2,-1
    80004856:	b745                	j	800047f6 <fileread+0x60>

0000000080004858 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004858:	715d                	addi	sp,sp,-80
    8000485a:	e486                	sd	ra,72(sp)
    8000485c:	e0a2                	sd	s0,64(sp)
    8000485e:	fc26                	sd	s1,56(sp)
    80004860:	f84a                	sd	s2,48(sp)
    80004862:	f44e                	sd	s3,40(sp)
    80004864:	f052                	sd	s4,32(sp)
    80004866:	ec56                	sd	s5,24(sp)
    80004868:	e85a                	sd	s6,16(sp)
    8000486a:	e45e                	sd	s7,8(sp)
    8000486c:	e062                	sd	s8,0(sp)
    8000486e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004870:	00954783          	lbu	a5,9(a0)
    80004874:	10078663          	beqz	a5,80004980 <filewrite+0x128>
    80004878:	892a                	mv	s2,a0
    8000487a:	8aae                	mv	s5,a1
    8000487c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000487e:	411c                	lw	a5,0(a0)
    80004880:	4705                	li	a4,1
    80004882:	02e78263          	beq	a5,a4,800048a6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004886:	470d                	li	a4,3
    80004888:	02e78663          	beq	a5,a4,800048b4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000488c:	4709                	li	a4,2
    8000488e:	0ee79163          	bne	a5,a4,80004970 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004892:	0ac05d63          	blez	a2,8000494c <filewrite+0xf4>
    int i = 0;
    80004896:	4981                	li	s3,0
    80004898:	6b05                	lui	s6,0x1
    8000489a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000489e:	6b85                	lui	s7,0x1
    800048a0:	c00b8b9b          	addiw	s7,s7,-1024
    800048a4:	a861                	j	8000493c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048a6:	6908                	ld	a0,16(a0)
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	22e080e7          	jalr	558(ra) # 80004ad6 <pipewrite>
    800048b0:	8a2a                	mv	s4,a0
    800048b2:	a045                	j	80004952 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048b4:	02451783          	lh	a5,36(a0)
    800048b8:	03079693          	slli	a3,a5,0x30
    800048bc:	92c1                	srli	a3,a3,0x30
    800048be:	4725                	li	a4,9
    800048c0:	0cd76263          	bltu	a4,a3,80004984 <filewrite+0x12c>
    800048c4:	0792                	slli	a5,a5,0x4
    800048c6:	0001c717          	auipc	a4,0x1c
    800048ca:	77270713          	addi	a4,a4,1906 # 80021038 <devsw>
    800048ce:	97ba                	add	a5,a5,a4
    800048d0:	679c                	ld	a5,8(a5)
    800048d2:	cbdd                	beqz	a5,80004988 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048d4:	4505                	li	a0,1
    800048d6:	9782                	jalr	a5
    800048d8:	8a2a                	mv	s4,a0
    800048da:	a8a5                	j	80004952 <filewrite+0xfa>
    800048dc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	8b0080e7          	jalr	-1872(ra) # 80004190 <begin_op>
      ilock(f->ip);
    800048e8:	01893503          	ld	a0,24(s2)
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	ee2080e7          	jalr	-286(ra) # 800037ce <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048f4:	8762                	mv	a4,s8
    800048f6:	02092683          	lw	a3,32(s2)
    800048fa:	01598633          	add	a2,s3,s5
    800048fe:	4585                	li	a1,1
    80004900:	01893503          	ld	a0,24(s2)
    80004904:	fffff097          	auipc	ra,0xfffff
    80004908:	276080e7          	jalr	630(ra) # 80003b7a <writei>
    8000490c:	84aa                	mv	s1,a0
    8000490e:	00a05763          	blez	a0,8000491c <filewrite+0xc4>
        f->off += r;
    80004912:	02092783          	lw	a5,32(s2)
    80004916:	9fa9                	addw	a5,a5,a0
    80004918:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000491c:	01893503          	ld	a0,24(s2)
    80004920:	fffff097          	auipc	ra,0xfffff
    80004924:	f70080e7          	jalr	-144(ra) # 80003890 <iunlock>
      end_op();
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	8e8080e7          	jalr	-1816(ra) # 80004210 <end_op>

      if(r != n1){
    80004930:	009c1f63          	bne	s8,s1,8000494e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004934:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004938:	0149db63          	bge	s3,s4,8000494e <filewrite+0xf6>
      int n1 = n - i;
    8000493c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004940:	84be                	mv	s1,a5
    80004942:	2781                	sext.w	a5,a5
    80004944:	f8fb5ce3          	bge	s6,a5,800048dc <filewrite+0x84>
    80004948:	84de                	mv	s1,s7
    8000494a:	bf49                	j	800048dc <filewrite+0x84>
    int i = 0;
    8000494c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000494e:	013a1f63          	bne	s4,s3,8000496c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004952:	8552                	mv	a0,s4
    80004954:	60a6                	ld	ra,72(sp)
    80004956:	6406                	ld	s0,64(sp)
    80004958:	74e2                	ld	s1,56(sp)
    8000495a:	7942                	ld	s2,48(sp)
    8000495c:	79a2                	ld	s3,40(sp)
    8000495e:	7a02                	ld	s4,32(sp)
    80004960:	6ae2                	ld	s5,24(sp)
    80004962:	6b42                	ld	s6,16(sp)
    80004964:	6ba2                	ld	s7,8(sp)
    80004966:	6c02                	ld	s8,0(sp)
    80004968:	6161                	addi	sp,sp,80
    8000496a:	8082                	ret
    ret = (i == n ? n : -1);
    8000496c:	5a7d                	li	s4,-1
    8000496e:	b7d5                	j	80004952 <filewrite+0xfa>
    panic("filewrite");
    80004970:	00004517          	auipc	a0,0x4
    80004974:	db050513          	addi	a0,a0,-592 # 80008720 <syscalls+0x278>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	bcc080e7          	jalr	-1076(ra) # 80000544 <panic>
    return -1;
    80004980:	5a7d                	li	s4,-1
    80004982:	bfc1                	j	80004952 <filewrite+0xfa>
      return -1;
    80004984:	5a7d                	li	s4,-1
    80004986:	b7f1                	j	80004952 <filewrite+0xfa>
    80004988:	5a7d                	li	s4,-1
    8000498a:	b7e1                	j	80004952 <filewrite+0xfa>

000000008000498c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000498c:	7179                	addi	sp,sp,-48
    8000498e:	f406                	sd	ra,40(sp)
    80004990:	f022                	sd	s0,32(sp)
    80004992:	ec26                	sd	s1,24(sp)
    80004994:	e84a                	sd	s2,16(sp)
    80004996:	e44e                	sd	s3,8(sp)
    80004998:	e052                	sd	s4,0(sp)
    8000499a:	1800                	addi	s0,sp,48
    8000499c:	84aa                	mv	s1,a0
    8000499e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049a0:	0005b023          	sd	zero,0(a1)
    800049a4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	bf8080e7          	jalr	-1032(ra) # 800045a0 <filealloc>
    800049b0:	e088                	sd	a0,0(s1)
    800049b2:	c551                	beqz	a0,80004a3e <pipealloc+0xb2>
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	bec080e7          	jalr	-1044(ra) # 800045a0 <filealloc>
    800049bc:	00aa3023          	sd	a0,0(s4)
    800049c0:	c92d                	beqz	a0,80004a32 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	138080e7          	jalr	312(ra) # 80000afa <kalloc>
    800049ca:	892a                	mv	s2,a0
    800049cc:	c125                	beqz	a0,80004a2c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049ce:	4985                	li	s3,1
    800049d0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049d4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049d8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049dc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049e0:	00004597          	auipc	a1,0x4
    800049e4:	d5058593          	addi	a1,a1,-688 # 80008730 <syscalls+0x288>
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	172080e7          	jalr	370(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800049f0:	609c                	ld	a5,0(s1)
    800049f2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049f6:	609c                	ld	a5,0(s1)
    800049f8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049fc:	609c                	ld	a5,0(s1)
    800049fe:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a02:	609c                	ld	a5,0(s1)
    80004a04:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a08:	000a3783          	ld	a5,0(s4)
    80004a0c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a10:	000a3783          	ld	a5,0(s4)
    80004a14:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a18:	000a3783          	ld	a5,0(s4)
    80004a1c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a20:	000a3783          	ld	a5,0(s4)
    80004a24:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a28:	4501                	li	a0,0
    80004a2a:	a025                	j	80004a52 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a2c:	6088                	ld	a0,0(s1)
    80004a2e:	e501                	bnez	a0,80004a36 <pipealloc+0xaa>
    80004a30:	a039                	j	80004a3e <pipealloc+0xb2>
    80004a32:	6088                	ld	a0,0(s1)
    80004a34:	c51d                	beqz	a0,80004a62 <pipealloc+0xd6>
    fileclose(*f0);
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	c26080e7          	jalr	-986(ra) # 8000465c <fileclose>
  if(*f1)
    80004a3e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a42:	557d                	li	a0,-1
  if(*f1)
    80004a44:	c799                	beqz	a5,80004a52 <pipealloc+0xc6>
    fileclose(*f1);
    80004a46:	853e                	mv	a0,a5
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	c14080e7          	jalr	-1004(ra) # 8000465c <fileclose>
  return -1;
    80004a50:	557d                	li	a0,-1
}
    80004a52:	70a2                	ld	ra,40(sp)
    80004a54:	7402                	ld	s0,32(sp)
    80004a56:	64e2                	ld	s1,24(sp)
    80004a58:	6942                	ld	s2,16(sp)
    80004a5a:	69a2                	ld	s3,8(sp)
    80004a5c:	6a02                	ld	s4,0(sp)
    80004a5e:	6145                	addi	sp,sp,48
    80004a60:	8082                	ret
  return -1;
    80004a62:	557d                	li	a0,-1
    80004a64:	b7fd                	j	80004a52 <pipealloc+0xc6>

0000000080004a66 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a66:	1101                	addi	sp,sp,-32
    80004a68:	ec06                	sd	ra,24(sp)
    80004a6a:	e822                	sd	s0,16(sp)
    80004a6c:	e426                	sd	s1,8(sp)
    80004a6e:	e04a                	sd	s2,0(sp)
    80004a70:	1000                	addi	s0,sp,32
    80004a72:	84aa                	mv	s1,a0
    80004a74:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	174080e7          	jalr	372(ra) # 80000bea <acquire>
  if(writable){
    80004a7e:	02090d63          	beqz	s2,80004ab8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a82:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a86:	21848513          	addi	a0,s1,536
    80004a8a:	ffffd097          	auipc	ra,0xffffd
    80004a8e:	6bc080e7          	jalr	1724(ra) # 80002146 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a92:	2204b783          	ld	a5,544(s1)
    80004a96:	eb95                	bnez	a5,80004aca <pipeclose+0x64>
    release(&pi->lock);
    80004a98:	8526                	mv	a0,s1
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	204080e7          	jalr	516(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	f5a080e7          	jalr	-166(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004aac:	60e2                	ld	ra,24(sp)
    80004aae:	6442                	ld	s0,16(sp)
    80004ab0:	64a2                	ld	s1,8(sp)
    80004ab2:	6902                	ld	s2,0(sp)
    80004ab4:	6105                	addi	sp,sp,32
    80004ab6:	8082                	ret
    pi->readopen = 0;
    80004ab8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004abc:	21c48513          	addi	a0,s1,540
    80004ac0:	ffffd097          	auipc	ra,0xffffd
    80004ac4:	686080e7          	jalr	1670(ra) # 80002146 <wakeup>
    80004ac8:	b7e9                	j	80004a92 <pipeclose+0x2c>
    release(&pi->lock);
    80004aca:	8526                	mv	a0,s1
    80004acc:	ffffc097          	auipc	ra,0xffffc
    80004ad0:	1d2080e7          	jalr	466(ra) # 80000c9e <release>
}
    80004ad4:	bfe1                	j	80004aac <pipeclose+0x46>

0000000080004ad6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ad6:	7159                	addi	sp,sp,-112
    80004ad8:	f486                	sd	ra,104(sp)
    80004ada:	f0a2                	sd	s0,96(sp)
    80004adc:	eca6                	sd	s1,88(sp)
    80004ade:	e8ca                	sd	s2,80(sp)
    80004ae0:	e4ce                	sd	s3,72(sp)
    80004ae2:	e0d2                	sd	s4,64(sp)
    80004ae4:	fc56                	sd	s5,56(sp)
    80004ae6:	f85a                	sd	s6,48(sp)
    80004ae8:	f45e                	sd	s7,40(sp)
    80004aea:	f062                	sd	s8,32(sp)
    80004aec:	ec66                	sd	s9,24(sp)
    80004aee:	1880                	addi	s0,sp,112
    80004af0:	84aa                	mv	s1,a0
    80004af2:	8aae                	mv	s5,a1
    80004af4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	ed0080e7          	jalr	-304(ra) # 800019c6 <myproc>
    80004afe:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	0e8080e7          	jalr	232(ra) # 80000bea <acquire>
  while(i < n){
    80004b0a:	0d405463          	blez	s4,80004bd2 <pipewrite+0xfc>
    80004b0e:	8ba6                	mv	s7,s1
  int i = 0;
    80004b10:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b12:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b14:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b18:	21c48c13          	addi	s8,s1,540
    80004b1c:	a08d                	j	80004b7e <pipewrite+0xa8>
      release(&pi->lock);
    80004b1e:	8526                	mv	a0,s1
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	17e080e7          	jalr	382(ra) # 80000c9e <release>
      return -1;
    80004b28:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b2a:	854a                	mv	a0,s2
    80004b2c:	70a6                	ld	ra,104(sp)
    80004b2e:	7406                	ld	s0,96(sp)
    80004b30:	64e6                	ld	s1,88(sp)
    80004b32:	6946                	ld	s2,80(sp)
    80004b34:	69a6                	ld	s3,72(sp)
    80004b36:	6a06                	ld	s4,64(sp)
    80004b38:	7ae2                	ld	s5,56(sp)
    80004b3a:	7b42                	ld	s6,48(sp)
    80004b3c:	7ba2                	ld	s7,40(sp)
    80004b3e:	7c02                	ld	s8,32(sp)
    80004b40:	6ce2                	ld	s9,24(sp)
    80004b42:	6165                	addi	sp,sp,112
    80004b44:	8082                	ret
      wakeup(&pi->nread);
    80004b46:	8566                	mv	a0,s9
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	5fe080e7          	jalr	1534(ra) # 80002146 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b50:	85de                	mv	a1,s7
    80004b52:	8562                	mv	a0,s8
    80004b54:	ffffd097          	auipc	ra,0xffffd
    80004b58:	58e080e7          	jalr	1422(ra) # 800020e2 <sleep>
    80004b5c:	a839                	j	80004b7a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b5e:	21c4a783          	lw	a5,540(s1)
    80004b62:	0017871b          	addiw	a4,a5,1
    80004b66:	20e4ae23          	sw	a4,540(s1)
    80004b6a:	1ff7f793          	andi	a5,a5,511
    80004b6e:	97a6                	add	a5,a5,s1
    80004b70:	f9f44703          	lbu	a4,-97(s0)
    80004b74:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b78:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b7a:	05495063          	bge	s2,s4,80004bba <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004b7e:	2204a783          	lw	a5,544(s1)
    80004b82:	dfd1                	beqz	a5,80004b1e <pipewrite+0x48>
    80004b84:	854e                	mv	a0,s3
    80004b86:	ffffe097          	auipc	ra,0xffffe
    80004b8a:	804080e7          	jalr	-2044(ra) # 8000238a <killed>
    80004b8e:	f941                	bnez	a0,80004b1e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b90:	2184a783          	lw	a5,536(s1)
    80004b94:	21c4a703          	lw	a4,540(s1)
    80004b98:	2007879b          	addiw	a5,a5,512
    80004b9c:	faf705e3          	beq	a4,a5,80004b46 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba0:	4685                	li	a3,1
    80004ba2:	01590633          	add	a2,s2,s5
    80004ba6:	f9f40593          	addi	a1,s0,-97
    80004baa:	0609b503          	ld	a0,96(s3)
    80004bae:	ffffd097          	auipc	ra,0xffffd
    80004bb2:	b62080e7          	jalr	-1182(ra) # 80001710 <copyin>
    80004bb6:	fb6514e3          	bne	a0,s6,80004b5e <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bba:	21848513          	addi	a0,s1,536
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	588080e7          	jalr	1416(ra) # 80002146 <wakeup>
  release(&pi->lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	0d6080e7          	jalr	214(ra) # 80000c9e <release>
  return i;
    80004bd0:	bfa9                	j	80004b2a <pipewrite+0x54>
  int i = 0;
    80004bd2:	4901                	li	s2,0
    80004bd4:	b7dd                	j	80004bba <pipewrite+0xe4>

0000000080004bd6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bd6:	715d                	addi	sp,sp,-80
    80004bd8:	e486                	sd	ra,72(sp)
    80004bda:	e0a2                	sd	s0,64(sp)
    80004bdc:	fc26                	sd	s1,56(sp)
    80004bde:	f84a                	sd	s2,48(sp)
    80004be0:	f44e                	sd	s3,40(sp)
    80004be2:	f052                	sd	s4,32(sp)
    80004be4:	ec56                	sd	s5,24(sp)
    80004be6:	e85a                	sd	s6,16(sp)
    80004be8:	0880                	addi	s0,sp,80
    80004bea:	84aa                	mv	s1,a0
    80004bec:	892e                	mv	s2,a1
    80004bee:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bf0:	ffffd097          	auipc	ra,0xffffd
    80004bf4:	dd6080e7          	jalr	-554(ra) # 800019c6 <myproc>
    80004bf8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bfa:	8b26                	mv	s6,s1
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	fec080e7          	jalr	-20(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c06:	2184a703          	lw	a4,536(s1)
    80004c0a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c0e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c12:	02f71763          	bne	a4,a5,80004c40 <piperead+0x6a>
    80004c16:	2244a783          	lw	a5,548(s1)
    80004c1a:	c39d                	beqz	a5,80004c40 <piperead+0x6a>
    if(killed(pr)){
    80004c1c:	8552                	mv	a0,s4
    80004c1e:	ffffd097          	auipc	ra,0xffffd
    80004c22:	76c080e7          	jalr	1900(ra) # 8000238a <killed>
    80004c26:	e941                	bnez	a0,80004cb6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c28:	85da                	mv	a1,s6
    80004c2a:	854e                	mv	a0,s3
    80004c2c:	ffffd097          	auipc	ra,0xffffd
    80004c30:	4b6080e7          	jalr	1206(ra) # 800020e2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c34:	2184a703          	lw	a4,536(s1)
    80004c38:	21c4a783          	lw	a5,540(s1)
    80004c3c:	fcf70de3          	beq	a4,a5,80004c16 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c40:	09505263          	blez	s5,80004cc4 <piperead+0xee>
    80004c44:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c46:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c48:	2184a783          	lw	a5,536(s1)
    80004c4c:	21c4a703          	lw	a4,540(s1)
    80004c50:	02f70d63          	beq	a4,a5,80004c8a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c54:	0017871b          	addiw	a4,a5,1
    80004c58:	20e4ac23          	sw	a4,536(s1)
    80004c5c:	1ff7f793          	andi	a5,a5,511
    80004c60:	97a6                	add	a5,a5,s1
    80004c62:	0187c783          	lbu	a5,24(a5)
    80004c66:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c6a:	4685                	li	a3,1
    80004c6c:	fbf40613          	addi	a2,s0,-65
    80004c70:	85ca                	mv	a1,s2
    80004c72:	060a3503          	ld	a0,96(s4)
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	a0e080e7          	jalr	-1522(ra) # 80001684 <copyout>
    80004c7e:	01650663          	beq	a0,s6,80004c8a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c82:	2985                	addiw	s3,s3,1
    80004c84:	0905                	addi	s2,s2,1
    80004c86:	fd3a91e3          	bne	s5,s3,80004c48 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c8a:	21c48513          	addi	a0,s1,540
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	4b8080e7          	jalr	1208(ra) # 80002146 <wakeup>
  release(&pi->lock);
    80004c96:	8526                	mv	a0,s1
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	006080e7          	jalr	6(ra) # 80000c9e <release>
  return i;
}
    80004ca0:	854e                	mv	a0,s3
    80004ca2:	60a6                	ld	ra,72(sp)
    80004ca4:	6406                	ld	s0,64(sp)
    80004ca6:	74e2                	ld	s1,56(sp)
    80004ca8:	7942                	ld	s2,48(sp)
    80004caa:	79a2                	ld	s3,40(sp)
    80004cac:	7a02                	ld	s4,32(sp)
    80004cae:	6ae2                	ld	s5,24(sp)
    80004cb0:	6b42                	ld	s6,16(sp)
    80004cb2:	6161                	addi	sp,sp,80
    80004cb4:	8082                	ret
      release(&pi->lock);
    80004cb6:	8526                	mv	a0,s1
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	fe6080e7          	jalr	-26(ra) # 80000c9e <release>
      return -1;
    80004cc0:	59fd                	li	s3,-1
    80004cc2:	bff9                	j	80004ca0 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc4:	4981                	li	s3,0
    80004cc6:	b7d1                	j	80004c8a <piperead+0xb4>

0000000080004cc8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cc8:	1141                	addi	sp,sp,-16
    80004cca:	e422                	sd	s0,8(sp)
    80004ccc:	0800                	addi	s0,sp,16
    80004cce:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cd0:	8905                	andi	a0,a0,1
    80004cd2:	c111                	beqz	a0,80004cd6 <flags2perm+0xe>
      perm = PTE_X;
    80004cd4:	4521                	li	a0,8
    if(flags & 0x2)
    80004cd6:	8b89                	andi	a5,a5,2
    80004cd8:	c399                	beqz	a5,80004cde <flags2perm+0x16>
      perm |= PTE_W;
    80004cda:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cde:	6422                	ld	s0,8(sp)
    80004ce0:	0141                	addi	sp,sp,16
    80004ce2:	8082                	ret

0000000080004ce4 <exec>:

int
exec(char *path, char **argv)
{
    80004ce4:	df010113          	addi	sp,sp,-528
    80004ce8:	20113423          	sd	ra,520(sp)
    80004cec:	20813023          	sd	s0,512(sp)
    80004cf0:	ffa6                	sd	s1,504(sp)
    80004cf2:	fbca                	sd	s2,496(sp)
    80004cf4:	f7ce                	sd	s3,488(sp)
    80004cf6:	f3d2                	sd	s4,480(sp)
    80004cf8:	efd6                	sd	s5,472(sp)
    80004cfa:	ebda                	sd	s6,464(sp)
    80004cfc:	e7de                	sd	s7,456(sp)
    80004cfe:	e3e2                	sd	s8,448(sp)
    80004d00:	ff66                	sd	s9,440(sp)
    80004d02:	fb6a                	sd	s10,432(sp)
    80004d04:	f76e                	sd	s11,424(sp)
    80004d06:	0c00                	addi	s0,sp,528
    80004d08:	84aa                	mv	s1,a0
    80004d0a:	dea43c23          	sd	a0,-520(s0)
    80004d0e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	cb4080e7          	jalr	-844(ra) # 800019c6 <myproc>
    80004d1a:	892a                	mv	s2,a0

  begin_op();
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	474080e7          	jalr	1140(ra) # 80004190 <begin_op>

  if((ip = namei(path)) == 0){
    80004d24:	8526                	mv	a0,s1
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	24e080e7          	jalr	590(ra) # 80003f74 <namei>
    80004d2e:	c92d                	beqz	a0,80004da0 <exec+0xbc>
    80004d30:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	a9c080e7          	jalr	-1380(ra) # 800037ce <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d3a:	04000713          	li	a4,64
    80004d3e:	4681                	li	a3,0
    80004d40:	e5040613          	addi	a2,s0,-432
    80004d44:	4581                	li	a1,0
    80004d46:	8526                	mv	a0,s1
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	d3a080e7          	jalr	-710(ra) # 80003a82 <readi>
    80004d50:	04000793          	li	a5,64
    80004d54:	00f51a63          	bne	a0,a5,80004d68 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d58:	e5042703          	lw	a4,-432(s0)
    80004d5c:	464c47b7          	lui	a5,0x464c4
    80004d60:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d64:	04f70463          	beq	a4,a5,80004dac <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d68:	8526                	mv	a0,s1
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	cc6080e7          	jalr	-826(ra) # 80003a30 <iunlockput>
    end_op();
    80004d72:	fffff097          	auipc	ra,0xfffff
    80004d76:	49e080e7          	jalr	1182(ra) # 80004210 <end_op>
  }
  return -1;
    80004d7a:	557d                	li	a0,-1
}
    80004d7c:	20813083          	ld	ra,520(sp)
    80004d80:	20013403          	ld	s0,512(sp)
    80004d84:	74fe                	ld	s1,504(sp)
    80004d86:	795e                	ld	s2,496(sp)
    80004d88:	79be                	ld	s3,488(sp)
    80004d8a:	7a1e                	ld	s4,480(sp)
    80004d8c:	6afe                	ld	s5,472(sp)
    80004d8e:	6b5e                	ld	s6,464(sp)
    80004d90:	6bbe                	ld	s7,456(sp)
    80004d92:	6c1e                	ld	s8,448(sp)
    80004d94:	7cfa                	ld	s9,440(sp)
    80004d96:	7d5a                	ld	s10,432(sp)
    80004d98:	7dba                	ld	s11,424(sp)
    80004d9a:	21010113          	addi	sp,sp,528
    80004d9e:	8082                	ret
    end_op();
    80004da0:	fffff097          	auipc	ra,0xfffff
    80004da4:	470080e7          	jalr	1136(ra) # 80004210 <end_op>
    return -1;
    80004da8:	557d                	li	a0,-1
    80004daa:	bfc9                	j	80004d7c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dac:	854a                	mv	a0,s2
    80004dae:	ffffd097          	auipc	ra,0xffffd
    80004db2:	cdc080e7          	jalr	-804(ra) # 80001a8a <proc_pagetable>
    80004db6:	8baa                	mv	s7,a0
    80004db8:	d945                	beqz	a0,80004d68 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dba:	e7042983          	lw	s3,-400(s0)
    80004dbe:	e8845783          	lhu	a5,-376(s0)
    80004dc2:	c7ad                	beqz	a5,80004e2c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dc4:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dc6:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004dc8:	6c85                	lui	s9,0x1
    80004dca:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dce:	def43823          	sd	a5,-528(s0)
    80004dd2:	ac0d                	j	80005004 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dd4:	00004517          	auipc	a0,0x4
    80004dd8:	96450513          	addi	a0,a0,-1692 # 80008738 <syscalls+0x290>
    80004ddc:	ffffb097          	auipc	ra,0xffffb
    80004de0:	768080e7          	jalr	1896(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004de4:	8756                	mv	a4,s5
    80004de6:	012d86bb          	addw	a3,s11,s2
    80004dea:	4581                	li	a1,0
    80004dec:	8526                	mv	a0,s1
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	c94080e7          	jalr	-876(ra) # 80003a82 <readi>
    80004df6:	2501                	sext.w	a0,a0
    80004df8:	1aaa9a63          	bne	s5,a0,80004fac <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004dfc:	6785                	lui	a5,0x1
    80004dfe:	0127893b          	addw	s2,a5,s2
    80004e02:	77fd                	lui	a5,0xfffff
    80004e04:	01478a3b          	addw	s4,a5,s4
    80004e08:	1f897563          	bgeu	s2,s8,80004ff2 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004e0c:	02091593          	slli	a1,s2,0x20
    80004e10:	9181                	srli	a1,a1,0x20
    80004e12:	95ea                	add	a1,a1,s10
    80004e14:	855e                	mv	a0,s7
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	262080e7          	jalr	610(ra) # 80001078 <walkaddr>
    80004e1e:	862a                	mv	a2,a0
    if(pa == 0)
    80004e20:	d955                	beqz	a0,80004dd4 <exec+0xf0>
      n = PGSIZE;
    80004e22:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e24:	fd9a70e3          	bgeu	s4,s9,80004de4 <exec+0x100>
      n = sz - i;
    80004e28:	8ad2                	mv	s5,s4
    80004e2a:	bf6d                	j	80004de4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e2c:	4a01                	li	s4,0
  iunlockput(ip);
    80004e2e:	8526                	mv	a0,s1
    80004e30:	fffff097          	auipc	ra,0xfffff
    80004e34:	c00080e7          	jalr	-1024(ra) # 80003a30 <iunlockput>
  end_op();
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	3d8080e7          	jalr	984(ra) # 80004210 <end_op>
  p = myproc();
    80004e40:	ffffd097          	auipc	ra,0xffffd
    80004e44:	b86080e7          	jalr	-1146(ra) # 800019c6 <myproc>
    80004e48:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e4a:	05853d03          	ld	s10,88(a0)
  sz = PGROUNDUP(sz);
    80004e4e:	6785                	lui	a5,0x1
    80004e50:	17fd                	addi	a5,a5,-1
    80004e52:	9a3e                	add	s4,s4,a5
    80004e54:	757d                	lui	a0,0xfffff
    80004e56:	00aa77b3          	and	a5,s4,a0
    80004e5a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e5e:	4691                	li	a3,4
    80004e60:	6609                	lui	a2,0x2
    80004e62:	963e                	add	a2,a2,a5
    80004e64:	85be                	mv	a1,a5
    80004e66:	855e                	mv	a0,s7
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	5c4080e7          	jalr	1476(ra) # 8000142c <uvmalloc>
    80004e70:	8b2a                	mv	s6,a0
  ip = 0;
    80004e72:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e74:	12050c63          	beqz	a0,80004fac <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e78:	75f9                	lui	a1,0xffffe
    80004e7a:	95aa                	add	a1,a1,a0
    80004e7c:	855e                	mv	a0,s7
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	7d4080e7          	jalr	2004(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e86:	7c7d                	lui	s8,0xfffff
    80004e88:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e8a:	e0043783          	ld	a5,-512(s0)
    80004e8e:	6388                	ld	a0,0(a5)
    80004e90:	c535                	beqz	a0,80004efc <exec+0x218>
    80004e92:	e9040993          	addi	s3,s0,-368
    80004e96:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e9a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	fce080e7          	jalr	-50(ra) # 80000e6a <strlen>
    80004ea4:	2505                	addiw	a0,a0,1
    80004ea6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004eaa:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004eae:	13896663          	bltu	s2,s8,80004fda <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eb2:	e0043d83          	ld	s11,-512(s0)
    80004eb6:	000dba03          	ld	s4,0(s11)
    80004eba:	8552                	mv	a0,s4
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	fae080e7          	jalr	-82(ra) # 80000e6a <strlen>
    80004ec4:	0015069b          	addiw	a3,a0,1
    80004ec8:	8652                	mv	a2,s4
    80004eca:	85ca                	mv	a1,s2
    80004ecc:	855e                	mv	a0,s7
    80004ece:	ffffc097          	auipc	ra,0xffffc
    80004ed2:	7b6080e7          	jalr	1974(ra) # 80001684 <copyout>
    80004ed6:	10054663          	bltz	a0,80004fe2 <exec+0x2fe>
    ustack[argc] = sp;
    80004eda:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ede:	0485                	addi	s1,s1,1
    80004ee0:	008d8793          	addi	a5,s11,8
    80004ee4:	e0f43023          	sd	a5,-512(s0)
    80004ee8:	008db503          	ld	a0,8(s11)
    80004eec:	c911                	beqz	a0,80004f00 <exec+0x21c>
    if(argc >= MAXARG)
    80004eee:	09a1                	addi	s3,s3,8
    80004ef0:	fb3c96e3          	bne	s9,s3,80004e9c <exec+0x1b8>
  sz = sz1;
    80004ef4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef8:	4481                	li	s1,0
    80004efa:	a84d                	j	80004fac <exec+0x2c8>
  sp = sz;
    80004efc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004efe:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f00:	00349793          	slli	a5,s1,0x3
    80004f04:	f9040713          	addi	a4,s0,-112
    80004f08:	97ba                	add	a5,a5,a4
    80004f0a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f0e:	00148693          	addi	a3,s1,1
    80004f12:	068e                	slli	a3,a3,0x3
    80004f14:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f18:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f1c:	01897663          	bgeu	s2,s8,80004f28 <exec+0x244>
  sz = sz1;
    80004f20:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f24:	4481                	li	s1,0
    80004f26:	a059                	j	80004fac <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f28:	e9040613          	addi	a2,s0,-368
    80004f2c:	85ca                	mv	a1,s2
    80004f2e:	855e                	mv	a0,s7
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	754080e7          	jalr	1876(ra) # 80001684 <copyout>
    80004f38:	0a054963          	bltz	a0,80004fea <exec+0x306>
  p->trapframe->a1 = sp;
    80004f3c:	068ab783          	ld	a5,104(s5)
    80004f40:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f44:	df843783          	ld	a5,-520(s0)
    80004f48:	0007c703          	lbu	a4,0(a5)
    80004f4c:	cf11                	beqz	a4,80004f68 <exec+0x284>
    80004f4e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f50:	02f00693          	li	a3,47
    80004f54:	a039                	j	80004f62 <exec+0x27e>
      last = s+1;
    80004f56:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f5a:	0785                	addi	a5,a5,1
    80004f5c:	fff7c703          	lbu	a4,-1(a5)
    80004f60:	c701                	beqz	a4,80004f68 <exec+0x284>
    if(*s == '/')
    80004f62:	fed71ce3          	bne	a4,a3,80004f5a <exec+0x276>
    80004f66:	bfc5                	j	80004f56 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f68:	4641                	li	a2,16
    80004f6a:	df843583          	ld	a1,-520(s0)
    80004f6e:	168a8513          	addi	a0,s5,360
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	ec6080e7          	jalr	-314(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f7a:	060ab503          	ld	a0,96(s5)
  p->pagetable = pagetable;
    80004f7e:	077ab023          	sd	s7,96(s5)
  p->sz = sz;
    80004f82:	056abc23          	sd	s6,88(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f86:	068ab783          	ld	a5,104(s5)
    80004f8a:	e6843703          	ld	a4,-408(s0)
    80004f8e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f90:	068ab783          	ld	a5,104(s5)
    80004f94:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f98:	85ea                	mv	a1,s10
    80004f9a:	ffffd097          	auipc	ra,0xffffd
    80004f9e:	b8c080e7          	jalr	-1140(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fa2:	0004851b          	sext.w	a0,s1
    80004fa6:	bbd9                	j	80004d7c <exec+0x98>
    80004fa8:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fac:	e0843583          	ld	a1,-504(s0)
    80004fb0:	855e                	mv	a0,s7
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	b74080e7          	jalr	-1164(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004fba:	da0497e3          	bnez	s1,80004d68 <exec+0x84>
  return -1;
    80004fbe:	557d                	li	a0,-1
    80004fc0:	bb75                	j	80004d7c <exec+0x98>
    80004fc2:	e1443423          	sd	s4,-504(s0)
    80004fc6:	b7dd                	j	80004fac <exec+0x2c8>
    80004fc8:	e1443423          	sd	s4,-504(s0)
    80004fcc:	b7c5                	j	80004fac <exec+0x2c8>
    80004fce:	e1443423          	sd	s4,-504(s0)
    80004fd2:	bfe9                	j	80004fac <exec+0x2c8>
    80004fd4:	e1443423          	sd	s4,-504(s0)
    80004fd8:	bfd1                	j	80004fac <exec+0x2c8>
  sz = sz1;
    80004fda:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fde:	4481                	li	s1,0
    80004fe0:	b7f1                	j	80004fac <exec+0x2c8>
  sz = sz1;
    80004fe2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe6:	4481                	li	s1,0
    80004fe8:	b7d1                	j	80004fac <exec+0x2c8>
  sz = sz1;
    80004fea:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fee:	4481                	li	s1,0
    80004ff0:	bf75                	j	80004fac <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ff2:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ff6:	2b05                	addiw	s6,s6,1
    80004ff8:	0389899b          	addiw	s3,s3,56
    80004ffc:	e8845783          	lhu	a5,-376(s0)
    80005000:	e2fb57e3          	bge	s6,a5,80004e2e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005004:	2981                	sext.w	s3,s3
    80005006:	03800713          	li	a4,56
    8000500a:	86ce                	mv	a3,s3
    8000500c:	e1840613          	addi	a2,s0,-488
    80005010:	4581                	li	a1,0
    80005012:	8526                	mv	a0,s1
    80005014:	fffff097          	auipc	ra,0xfffff
    80005018:	a6e080e7          	jalr	-1426(ra) # 80003a82 <readi>
    8000501c:	03800793          	li	a5,56
    80005020:	f8f514e3          	bne	a0,a5,80004fa8 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005024:	e1842783          	lw	a5,-488(s0)
    80005028:	4705                	li	a4,1
    8000502a:	fce796e3          	bne	a5,a4,80004ff6 <exec+0x312>
    if(ph.memsz < ph.filesz)
    8000502e:	e4043903          	ld	s2,-448(s0)
    80005032:	e3843783          	ld	a5,-456(s0)
    80005036:	f8f966e3          	bltu	s2,a5,80004fc2 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000503a:	e2843783          	ld	a5,-472(s0)
    8000503e:	993e                	add	s2,s2,a5
    80005040:	f8f964e3          	bltu	s2,a5,80004fc8 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005044:	df043703          	ld	a4,-528(s0)
    80005048:	8ff9                	and	a5,a5,a4
    8000504a:	f3d1                	bnez	a5,80004fce <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000504c:	e1c42503          	lw	a0,-484(s0)
    80005050:	00000097          	auipc	ra,0x0
    80005054:	c78080e7          	jalr	-904(ra) # 80004cc8 <flags2perm>
    80005058:	86aa                	mv	a3,a0
    8000505a:	864a                	mv	a2,s2
    8000505c:	85d2                	mv	a1,s4
    8000505e:	855e                	mv	a0,s7
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	3cc080e7          	jalr	972(ra) # 8000142c <uvmalloc>
    80005068:	e0a43423          	sd	a0,-504(s0)
    8000506c:	d525                	beqz	a0,80004fd4 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000506e:	e2843d03          	ld	s10,-472(s0)
    80005072:	e2042d83          	lw	s11,-480(s0)
    80005076:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000507a:	f60c0ce3          	beqz	s8,80004ff2 <exec+0x30e>
    8000507e:	8a62                	mv	s4,s8
    80005080:	4901                	li	s2,0
    80005082:	b369                	j	80004e0c <exec+0x128>

0000000080005084 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005084:	7179                	addi	sp,sp,-48
    80005086:	f406                	sd	ra,40(sp)
    80005088:	f022                	sd	s0,32(sp)
    8000508a:	ec26                	sd	s1,24(sp)
    8000508c:	e84a                	sd	s2,16(sp)
    8000508e:	1800                	addi	s0,sp,48
    80005090:	892e                	mv	s2,a1
    80005092:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005094:	fdc40593          	addi	a1,s0,-36
    80005098:	ffffe097          	auipc	ra,0xffffe
    8000509c:	b88080e7          	jalr	-1144(ra) # 80002c20 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050a0:	fdc42703          	lw	a4,-36(s0)
    800050a4:	47bd                	li	a5,15
    800050a6:	02e7eb63          	bltu	a5,a4,800050dc <argfd+0x58>
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	91c080e7          	jalr	-1764(ra) # 800019c6 <myproc>
    800050b2:	fdc42703          	lw	a4,-36(s0)
    800050b6:	01c70793          	addi	a5,a4,28
    800050ba:	078e                	slli	a5,a5,0x3
    800050bc:	953e                	add	a0,a0,a5
    800050be:	611c                	ld	a5,0(a0)
    800050c0:	c385                	beqz	a5,800050e0 <argfd+0x5c>
    return -1;
  if(pfd)
    800050c2:	00090463          	beqz	s2,800050ca <argfd+0x46>
    *pfd = fd;
    800050c6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050ca:	4501                	li	a0,0
  if(pf)
    800050cc:	c091                	beqz	s1,800050d0 <argfd+0x4c>
    *pf = f;
    800050ce:	e09c                	sd	a5,0(s1)
}
    800050d0:	70a2                	ld	ra,40(sp)
    800050d2:	7402                	ld	s0,32(sp)
    800050d4:	64e2                	ld	s1,24(sp)
    800050d6:	6942                	ld	s2,16(sp)
    800050d8:	6145                	addi	sp,sp,48
    800050da:	8082                	ret
    return -1;
    800050dc:	557d                	li	a0,-1
    800050de:	bfcd                	j	800050d0 <argfd+0x4c>
    800050e0:	557d                	li	a0,-1
    800050e2:	b7fd                	j	800050d0 <argfd+0x4c>

00000000800050e4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050e4:	1101                	addi	sp,sp,-32
    800050e6:	ec06                	sd	ra,24(sp)
    800050e8:	e822                	sd	s0,16(sp)
    800050ea:	e426                	sd	s1,8(sp)
    800050ec:	1000                	addi	s0,sp,32
    800050ee:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050f0:	ffffd097          	auipc	ra,0xffffd
    800050f4:	8d6080e7          	jalr	-1834(ra) # 800019c6 <myproc>
    800050f8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050fa:	0e050793          	addi	a5,a0,224 # fffffffffffff0e0 <end+0xffffffff7ffdcf10>
    800050fe:	4501                	li	a0,0
    80005100:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005102:	6398                	ld	a4,0(a5)
    80005104:	cb19                	beqz	a4,8000511a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005106:	2505                	addiw	a0,a0,1
    80005108:	07a1                	addi	a5,a5,8
    8000510a:	fed51ce3          	bne	a0,a3,80005102 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000510e:	557d                	li	a0,-1
}
    80005110:	60e2                	ld	ra,24(sp)
    80005112:	6442                	ld	s0,16(sp)
    80005114:	64a2                	ld	s1,8(sp)
    80005116:	6105                	addi	sp,sp,32
    80005118:	8082                	ret
      p->ofile[fd] = f;
    8000511a:	01c50793          	addi	a5,a0,28
    8000511e:	078e                	slli	a5,a5,0x3
    80005120:	963e                	add	a2,a2,a5
    80005122:	e204                	sd	s1,0(a2)
      return fd;
    80005124:	b7f5                	j	80005110 <fdalloc+0x2c>

0000000080005126 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005126:	715d                	addi	sp,sp,-80
    80005128:	e486                	sd	ra,72(sp)
    8000512a:	e0a2                	sd	s0,64(sp)
    8000512c:	fc26                	sd	s1,56(sp)
    8000512e:	f84a                	sd	s2,48(sp)
    80005130:	f44e                	sd	s3,40(sp)
    80005132:	f052                	sd	s4,32(sp)
    80005134:	ec56                	sd	s5,24(sp)
    80005136:	e85a                	sd	s6,16(sp)
    80005138:	0880                	addi	s0,sp,80
    8000513a:	8b2e                	mv	s6,a1
    8000513c:	89b2                	mv	s3,a2
    8000513e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005140:	fb040593          	addi	a1,s0,-80
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	e4e080e7          	jalr	-434(ra) # 80003f92 <nameiparent>
    8000514c:	84aa                	mv	s1,a0
    8000514e:	16050063          	beqz	a0,800052ae <create+0x188>
    return 0;

  ilock(dp);
    80005152:	ffffe097          	auipc	ra,0xffffe
    80005156:	67c080e7          	jalr	1660(ra) # 800037ce <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000515a:	4601                	li	a2,0
    8000515c:	fb040593          	addi	a1,s0,-80
    80005160:	8526                	mv	a0,s1
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	b50080e7          	jalr	-1200(ra) # 80003cb2 <dirlookup>
    8000516a:	8aaa                	mv	s5,a0
    8000516c:	c931                	beqz	a0,800051c0 <create+0x9a>
    iunlockput(dp);
    8000516e:	8526                	mv	a0,s1
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	8c0080e7          	jalr	-1856(ra) # 80003a30 <iunlockput>
    ilock(ip);
    80005178:	8556                	mv	a0,s5
    8000517a:	ffffe097          	auipc	ra,0xffffe
    8000517e:	654080e7          	jalr	1620(ra) # 800037ce <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005182:	000b059b          	sext.w	a1,s6
    80005186:	4789                	li	a5,2
    80005188:	02f59563          	bne	a1,a5,800051b2 <create+0x8c>
    8000518c:	044ad783          	lhu	a5,68(s5)
    80005190:	37f9                	addiw	a5,a5,-2
    80005192:	17c2                	slli	a5,a5,0x30
    80005194:	93c1                	srli	a5,a5,0x30
    80005196:	4705                	li	a4,1
    80005198:	00f76d63          	bltu	a4,a5,800051b2 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000519c:	8556                	mv	a0,s5
    8000519e:	60a6                	ld	ra,72(sp)
    800051a0:	6406                	ld	s0,64(sp)
    800051a2:	74e2                	ld	s1,56(sp)
    800051a4:	7942                	ld	s2,48(sp)
    800051a6:	79a2                	ld	s3,40(sp)
    800051a8:	7a02                	ld	s4,32(sp)
    800051aa:	6ae2                	ld	s5,24(sp)
    800051ac:	6b42                	ld	s6,16(sp)
    800051ae:	6161                	addi	sp,sp,80
    800051b0:	8082                	ret
    iunlockput(ip);
    800051b2:	8556                	mv	a0,s5
    800051b4:	fffff097          	auipc	ra,0xfffff
    800051b8:	87c080e7          	jalr	-1924(ra) # 80003a30 <iunlockput>
    return 0;
    800051bc:	4a81                	li	s5,0
    800051be:	bff9                	j	8000519c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051c0:	85da                	mv	a1,s6
    800051c2:	4088                	lw	a0,0(s1)
    800051c4:	ffffe097          	auipc	ra,0xffffe
    800051c8:	46e080e7          	jalr	1134(ra) # 80003632 <ialloc>
    800051cc:	8a2a                	mv	s4,a0
    800051ce:	c921                	beqz	a0,8000521e <create+0xf8>
  ilock(ip);
    800051d0:	ffffe097          	auipc	ra,0xffffe
    800051d4:	5fe080e7          	jalr	1534(ra) # 800037ce <ilock>
  ip->major = major;
    800051d8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051dc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051e0:	4785                	li	a5,1
    800051e2:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800051e6:	8552                	mv	a0,s4
    800051e8:	ffffe097          	auipc	ra,0xffffe
    800051ec:	51c080e7          	jalr	1308(ra) # 80003704 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051f0:	000b059b          	sext.w	a1,s6
    800051f4:	4785                	li	a5,1
    800051f6:	02f58b63          	beq	a1,a5,8000522c <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800051fa:	004a2603          	lw	a2,4(s4)
    800051fe:	fb040593          	addi	a1,s0,-80
    80005202:	8526                	mv	a0,s1
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	cbe080e7          	jalr	-834(ra) # 80003ec2 <dirlink>
    8000520c:	06054f63          	bltz	a0,8000528a <create+0x164>
  iunlockput(dp);
    80005210:	8526                	mv	a0,s1
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	81e080e7          	jalr	-2018(ra) # 80003a30 <iunlockput>
  return ip;
    8000521a:	8ad2                	mv	s5,s4
    8000521c:	b741                	j	8000519c <create+0x76>
    iunlockput(dp);
    8000521e:	8526                	mv	a0,s1
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	810080e7          	jalr	-2032(ra) # 80003a30 <iunlockput>
    return 0;
    80005228:	8ad2                	mv	s5,s4
    8000522a:	bf8d                	j	8000519c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000522c:	004a2603          	lw	a2,4(s4)
    80005230:	00003597          	auipc	a1,0x3
    80005234:	52858593          	addi	a1,a1,1320 # 80008758 <syscalls+0x2b0>
    80005238:	8552                	mv	a0,s4
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	c88080e7          	jalr	-888(ra) # 80003ec2 <dirlink>
    80005242:	04054463          	bltz	a0,8000528a <create+0x164>
    80005246:	40d0                	lw	a2,4(s1)
    80005248:	00003597          	auipc	a1,0x3
    8000524c:	51858593          	addi	a1,a1,1304 # 80008760 <syscalls+0x2b8>
    80005250:	8552                	mv	a0,s4
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	c70080e7          	jalr	-912(ra) # 80003ec2 <dirlink>
    8000525a:	02054863          	bltz	a0,8000528a <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000525e:	004a2603          	lw	a2,4(s4)
    80005262:	fb040593          	addi	a1,s0,-80
    80005266:	8526                	mv	a0,s1
    80005268:	fffff097          	auipc	ra,0xfffff
    8000526c:	c5a080e7          	jalr	-934(ra) # 80003ec2 <dirlink>
    80005270:	00054d63          	bltz	a0,8000528a <create+0x164>
    dp->nlink++;  // for ".."
    80005274:	04a4d783          	lhu	a5,74(s1)
    80005278:	2785                	addiw	a5,a5,1
    8000527a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000527e:	8526                	mv	a0,s1
    80005280:	ffffe097          	auipc	ra,0xffffe
    80005284:	484080e7          	jalr	1156(ra) # 80003704 <iupdate>
    80005288:	b761                	j	80005210 <create+0xea>
  ip->nlink = 0;
    8000528a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000528e:	8552                	mv	a0,s4
    80005290:	ffffe097          	auipc	ra,0xffffe
    80005294:	474080e7          	jalr	1140(ra) # 80003704 <iupdate>
  iunlockput(ip);
    80005298:	8552                	mv	a0,s4
    8000529a:	ffffe097          	auipc	ra,0xffffe
    8000529e:	796080e7          	jalr	1942(ra) # 80003a30 <iunlockput>
  iunlockput(dp);
    800052a2:	8526                	mv	a0,s1
    800052a4:	ffffe097          	auipc	ra,0xffffe
    800052a8:	78c080e7          	jalr	1932(ra) # 80003a30 <iunlockput>
  return 0;
    800052ac:	bdc5                	j	8000519c <create+0x76>
    return 0;
    800052ae:	8aaa                	mv	s5,a0
    800052b0:	b5f5                	j	8000519c <create+0x76>

00000000800052b2 <sys_dup>:
{
    800052b2:	7179                	addi	sp,sp,-48
    800052b4:	f406                	sd	ra,40(sp)
    800052b6:	f022                	sd	s0,32(sp)
    800052b8:	ec26                	sd	s1,24(sp)
    800052ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052bc:	fd840613          	addi	a2,s0,-40
    800052c0:	4581                	li	a1,0
    800052c2:	4501                	li	a0,0
    800052c4:	00000097          	auipc	ra,0x0
    800052c8:	dc0080e7          	jalr	-576(ra) # 80005084 <argfd>
    return -1;
    800052cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052ce:	02054363          	bltz	a0,800052f4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052d2:	fd843503          	ld	a0,-40(s0)
    800052d6:	00000097          	auipc	ra,0x0
    800052da:	e0e080e7          	jalr	-498(ra) # 800050e4 <fdalloc>
    800052de:	84aa                	mv	s1,a0
    return -1;
    800052e0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052e2:	00054963          	bltz	a0,800052f4 <sys_dup+0x42>
  filedup(f);
    800052e6:	fd843503          	ld	a0,-40(s0)
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	320080e7          	jalr	800(ra) # 8000460a <filedup>
  return fd;
    800052f2:	87a6                	mv	a5,s1
}
    800052f4:	853e                	mv	a0,a5
    800052f6:	70a2                	ld	ra,40(sp)
    800052f8:	7402                	ld	s0,32(sp)
    800052fa:	64e2                	ld	s1,24(sp)
    800052fc:	6145                	addi	sp,sp,48
    800052fe:	8082                	ret

0000000080005300 <sys_read>:
{
    80005300:	7179                	addi	sp,sp,-48
    80005302:	f406                	sd	ra,40(sp)
    80005304:	f022                	sd	s0,32(sp)
    80005306:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005308:	fd840593          	addi	a1,s0,-40
    8000530c:	4505                	li	a0,1
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	932080e7          	jalr	-1742(ra) # 80002c40 <argaddr>
  argint(2, &n);
    80005316:	fe440593          	addi	a1,s0,-28
    8000531a:	4509                	li	a0,2
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	904080e7          	jalr	-1788(ra) # 80002c20 <argint>
  if(argfd(0, 0, &f) < 0)
    80005324:	fe840613          	addi	a2,s0,-24
    80005328:	4581                	li	a1,0
    8000532a:	4501                	li	a0,0
    8000532c:	00000097          	auipc	ra,0x0
    80005330:	d58080e7          	jalr	-680(ra) # 80005084 <argfd>
    80005334:	87aa                	mv	a5,a0
    return -1;
    80005336:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005338:	0007cc63          	bltz	a5,80005350 <sys_read+0x50>
  return fileread(f, p, n);
    8000533c:	fe442603          	lw	a2,-28(s0)
    80005340:	fd843583          	ld	a1,-40(s0)
    80005344:	fe843503          	ld	a0,-24(s0)
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	44e080e7          	jalr	1102(ra) # 80004796 <fileread>
}
    80005350:	70a2                	ld	ra,40(sp)
    80005352:	7402                	ld	s0,32(sp)
    80005354:	6145                	addi	sp,sp,48
    80005356:	8082                	ret

0000000080005358 <sys_write>:
{
    80005358:	7179                	addi	sp,sp,-48
    8000535a:	f406                	sd	ra,40(sp)
    8000535c:	f022                	sd	s0,32(sp)
    8000535e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005360:	fd840593          	addi	a1,s0,-40
    80005364:	4505                	li	a0,1
    80005366:	ffffe097          	auipc	ra,0xffffe
    8000536a:	8da080e7          	jalr	-1830(ra) # 80002c40 <argaddr>
  argint(2, &n);
    8000536e:	fe440593          	addi	a1,s0,-28
    80005372:	4509                	li	a0,2
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	8ac080e7          	jalr	-1876(ra) # 80002c20 <argint>
  if(argfd(0, 0, &f) < 0)
    8000537c:	fe840613          	addi	a2,s0,-24
    80005380:	4581                	li	a1,0
    80005382:	4501                	li	a0,0
    80005384:	00000097          	auipc	ra,0x0
    80005388:	d00080e7          	jalr	-768(ra) # 80005084 <argfd>
    8000538c:	87aa                	mv	a5,a0
    return -1;
    8000538e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005390:	0007cc63          	bltz	a5,800053a8 <sys_write+0x50>
  return filewrite(f, p, n);
    80005394:	fe442603          	lw	a2,-28(s0)
    80005398:	fd843583          	ld	a1,-40(s0)
    8000539c:	fe843503          	ld	a0,-24(s0)
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	4b8080e7          	jalr	1208(ra) # 80004858 <filewrite>
}
    800053a8:	70a2                	ld	ra,40(sp)
    800053aa:	7402                	ld	s0,32(sp)
    800053ac:	6145                	addi	sp,sp,48
    800053ae:	8082                	ret

00000000800053b0 <sys_close>:
{
    800053b0:	1101                	addi	sp,sp,-32
    800053b2:	ec06                	sd	ra,24(sp)
    800053b4:	e822                	sd	s0,16(sp)
    800053b6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053b8:	fe040613          	addi	a2,s0,-32
    800053bc:	fec40593          	addi	a1,s0,-20
    800053c0:	4501                	li	a0,0
    800053c2:	00000097          	auipc	ra,0x0
    800053c6:	cc2080e7          	jalr	-830(ra) # 80005084 <argfd>
    return -1;
    800053ca:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053cc:	02054463          	bltz	a0,800053f4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053d0:	ffffc097          	auipc	ra,0xffffc
    800053d4:	5f6080e7          	jalr	1526(ra) # 800019c6 <myproc>
    800053d8:	fec42783          	lw	a5,-20(s0)
    800053dc:	07f1                	addi	a5,a5,28
    800053de:	078e                	slli	a5,a5,0x3
    800053e0:	97aa                	add	a5,a5,a0
    800053e2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053e6:	fe043503          	ld	a0,-32(s0)
    800053ea:	fffff097          	auipc	ra,0xfffff
    800053ee:	272080e7          	jalr	626(ra) # 8000465c <fileclose>
  return 0;
    800053f2:	4781                	li	a5,0
}
    800053f4:	853e                	mv	a0,a5
    800053f6:	60e2                	ld	ra,24(sp)
    800053f8:	6442                	ld	s0,16(sp)
    800053fa:	6105                	addi	sp,sp,32
    800053fc:	8082                	ret

00000000800053fe <sys_fstat>:
{
    800053fe:	1101                	addi	sp,sp,-32
    80005400:	ec06                	sd	ra,24(sp)
    80005402:	e822                	sd	s0,16(sp)
    80005404:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005406:	fe040593          	addi	a1,s0,-32
    8000540a:	4505                	li	a0,1
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	834080e7          	jalr	-1996(ra) # 80002c40 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005414:	fe840613          	addi	a2,s0,-24
    80005418:	4581                	li	a1,0
    8000541a:	4501                	li	a0,0
    8000541c:	00000097          	auipc	ra,0x0
    80005420:	c68080e7          	jalr	-920(ra) # 80005084 <argfd>
    80005424:	87aa                	mv	a5,a0
    return -1;
    80005426:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005428:	0007ca63          	bltz	a5,8000543c <sys_fstat+0x3e>
  return filestat(f, st);
    8000542c:	fe043583          	ld	a1,-32(s0)
    80005430:	fe843503          	ld	a0,-24(s0)
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	2f0080e7          	jalr	752(ra) # 80004724 <filestat>
}
    8000543c:	60e2                	ld	ra,24(sp)
    8000543e:	6442                	ld	s0,16(sp)
    80005440:	6105                	addi	sp,sp,32
    80005442:	8082                	ret

0000000080005444 <sys_link>:
{
    80005444:	7169                	addi	sp,sp,-304
    80005446:	f606                	sd	ra,296(sp)
    80005448:	f222                	sd	s0,288(sp)
    8000544a:	ee26                	sd	s1,280(sp)
    8000544c:	ea4a                	sd	s2,272(sp)
    8000544e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005450:	08000613          	li	a2,128
    80005454:	ed040593          	addi	a1,s0,-304
    80005458:	4501                	li	a0,0
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	806080e7          	jalr	-2042(ra) # 80002c60 <argstr>
    return -1;
    80005462:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005464:	10054e63          	bltz	a0,80005580 <sys_link+0x13c>
    80005468:	08000613          	li	a2,128
    8000546c:	f5040593          	addi	a1,s0,-176
    80005470:	4505                	li	a0,1
    80005472:	ffffd097          	auipc	ra,0xffffd
    80005476:	7ee080e7          	jalr	2030(ra) # 80002c60 <argstr>
    return -1;
    8000547a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000547c:	10054263          	bltz	a0,80005580 <sys_link+0x13c>
  begin_op();
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	d10080e7          	jalr	-752(ra) # 80004190 <begin_op>
  if((ip = namei(old)) == 0){
    80005488:	ed040513          	addi	a0,s0,-304
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	ae8080e7          	jalr	-1304(ra) # 80003f74 <namei>
    80005494:	84aa                	mv	s1,a0
    80005496:	c551                	beqz	a0,80005522 <sys_link+0xde>
  ilock(ip);
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	336080e7          	jalr	822(ra) # 800037ce <ilock>
  if(ip->type == T_DIR){
    800054a0:	04449703          	lh	a4,68(s1)
    800054a4:	4785                	li	a5,1
    800054a6:	08f70463          	beq	a4,a5,8000552e <sys_link+0xea>
  ip->nlink++;
    800054aa:	04a4d783          	lhu	a5,74(s1)
    800054ae:	2785                	addiw	a5,a5,1
    800054b0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054b4:	8526                	mv	a0,s1
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	24e080e7          	jalr	590(ra) # 80003704 <iupdate>
  iunlock(ip);
    800054be:	8526                	mv	a0,s1
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	3d0080e7          	jalr	976(ra) # 80003890 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054c8:	fd040593          	addi	a1,s0,-48
    800054cc:	f5040513          	addi	a0,s0,-176
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	ac2080e7          	jalr	-1342(ra) # 80003f92 <nameiparent>
    800054d8:	892a                	mv	s2,a0
    800054da:	c935                	beqz	a0,8000554e <sys_link+0x10a>
  ilock(dp);
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	2f2080e7          	jalr	754(ra) # 800037ce <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054e4:	00092703          	lw	a4,0(s2)
    800054e8:	409c                	lw	a5,0(s1)
    800054ea:	04f71d63          	bne	a4,a5,80005544 <sys_link+0x100>
    800054ee:	40d0                	lw	a2,4(s1)
    800054f0:	fd040593          	addi	a1,s0,-48
    800054f4:	854a                	mv	a0,s2
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	9cc080e7          	jalr	-1588(ra) # 80003ec2 <dirlink>
    800054fe:	04054363          	bltz	a0,80005544 <sys_link+0x100>
  iunlockput(dp);
    80005502:	854a                	mv	a0,s2
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	52c080e7          	jalr	1324(ra) # 80003a30 <iunlockput>
  iput(ip);
    8000550c:	8526                	mv	a0,s1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	47a080e7          	jalr	1146(ra) # 80003988 <iput>
  end_op();
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	cfa080e7          	jalr	-774(ra) # 80004210 <end_op>
  return 0;
    8000551e:	4781                	li	a5,0
    80005520:	a085                	j	80005580 <sys_link+0x13c>
    end_op();
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	cee080e7          	jalr	-786(ra) # 80004210 <end_op>
    return -1;
    8000552a:	57fd                	li	a5,-1
    8000552c:	a891                	j	80005580 <sys_link+0x13c>
    iunlockput(ip);
    8000552e:	8526                	mv	a0,s1
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	500080e7          	jalr	1280(ra) # 80003a30 <iunlockput>
    end_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	cd8080e7          	jalr	-808(ra) # 80004210 <end_op>
    return -1;
    80005540:	57fd                	li	a5,-1
    80005542:	a83d                	j	80005580 <sys_link+0x13c>
    iunlockput(dp);
    80005544:	854a                	mv	a0,s2
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	4ea080e7          	jalr	1258(ra) # 80003a30 <iunlockput>
  ilock(ip);
    8000554e:	8526                	mv	a0,s1
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	27e080e7          	jalr	638(ra) # 800037ce <ilock>
  ip->nlink--;
    80005558:	04a4d783          	lhu	a5,74(s1)
    8000555c:	37fd                	addiw	a5,a5,-1
    8000555e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005562:	8526                	mv	a0,s1
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	1a0080e7          	jalr	416(ra) # 80003704 <iupdate>
  iunlockput(ip);
    8000556c:	8526                	mv	a0,s1
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	4c2080e7          	jalr	1218(ra) # 80003a30 <iunlockput>
  end_op();
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	c9a080e7          	jalr	-870(ra) # 80004210 <end_op>
  return -1;
    8000557e:	57fd                	li	a5,-1
}
    80005580:	853e                	mv	a0,a5
    80005582:	70b2                	ld	ra,296(sp)
    80005584:	7412                	ld	s0,288(sp)
    80005586:	64f2                	ld	s1,280(sp)
    80005588:	6952                	ld	s2,272(sp)
    8000558a:	6155                	addi	sp,sp,304
    8000558c:	8082                	ret

000000008000558e <sys_unlink>:
{
    8000558e:	7151                	addi	sp,sp,-240
    80005590:	f586                	sd	ra,232(sp)
    80005592:	f1a2                	sd	s0,224(sp)
    80005594:	eda6                	sd	s1,216(sp)
    80005596:	e9ca                	sd	s2,208(sp)
    80005598:	e5ce                	sd	s3,200(sp)
    8000559a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000559c:	08000613          	li	a2,128
    800055a0:	f3040593          	addi	a1,s0,-208
    800055a4:	4501                	li	a0,0
    800055a6:	ffffd097          	auipc	ra,0xffffd
    800055aa:	6ba080e7          	jalr	1722(ra) # 80002c60 <argstr>
    800055ae:	18054163          	bltz	a0,80005730 <sys_unlink+0x1a2>
  begin_op();
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	bde080e7          	jalr	-1058(ra) # 80004190 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055ba:	fb040593          	addi	a1,s0,-80
    800055be:	f3040513          	addi	a0,s0,-208
    800055c2:	fffff097          	auipc	ra,0xfffff
    800055c6:	9d0080e7          	jalr	-1584(ra) # 80003f92 <nameiparent>
    800055ca:	84aa                	mv	s1,a0
    800055cc:	c979                	beqz	a0,800056a2 <sys_unlink+0x114>
  ilock(dp);
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	200080e7          	jalr	512(ra) # 800037ce <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055d6:	00003597          	auipc	a1,0x3
    800055da:	18258593          	addi	a1,a1,386 # 80008758 <syscalls+0x2b0>
    800055de:	fb040513          	addi	a0,s0,-80
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	6b6080e7          	jalr	1718(ra) # 80003c98 <namecmp>
    800055ea:	14050a63          	beqz	a0,8000573e <sys_unlink+0x1b0>
    800055ee:	00003597          	auipc	a1,0x3
    800055f2:	17258593          	addi	a1,a1,370 # 80008760 <syscalls+0x2b8>
    800055f6:	fb040513          	addi	a0,s0,-80
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	69e080e7          	jalr	1694(ra) # 80003c98 <namecmp>
    80005602:	12050e63          	beqz	a0,8000573e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005606:	f2c40613          	addi	a2,s0,-212
    8000560a:	fb040593          	addi	a1,s0,-80
    8000560e:	8526                	mv	a0,s1
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	6a2080e7          	jalr	1698(ra) # 80003cb2 <dirlookup>
    80005618:	892a                	mv	s2,a0
    8000561a:	12050263          	beqz	a0,8000573e <sys_unlink+0x1b0>
  ilock(ip);
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	1b0080e7          	jalr	432(ra) # 800037ce <ilock>
  if(ip->nlink < 1)
    80005626:	04a91783          	lh	a5,74(s2)
    8000562a:	08f05263          	blez	a5,800056ae <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000562e:	04491703          	lh	a4,68(s2)
    80005632:	4785                	li	a5,1
    80005634:	08f70563          	beq	a4,a5,800056be <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005638:	4641                	li	a2,16
    8000563a:	4581                	li	a1,0
    8000563c:	fc040513          	addi	a0,s0,-64
    80005640:	ffffb097          	auipc	ra,0xffffb
    80005644:	6a6080e7          	jalr	1702(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005648:	4741                	li	a4,16
    8000564a:	f2c42683          	lw	a3,-212(s0)
    8000564e:	fc040613          	addi	a2,s0,-64
    80005652:	4581                	li	a1,0
    80005654:	8526                	mv	a0,s1
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	524080e7          	jalr	1316(ra) # 80003b7a <writei>
    8000565e:	47c1                	li	a5,16
    80005660:	0af51563          	bne	a0,a5,8000570a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005664:	04491703          	lh	a4,68(s2)
    80005668:	4785                	li	a5,1
    8000566a:	0af70863          	beq	a4,a5,8000571a <sys_unlink+0x18c>
  iunlockput(dp);
    8000566e:	8526                	mv	a0,s1
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	3c0080e7          	jalr	960(ra) # 80003a30 <iunlockput>
  ip->nlink--;
    80005678:	04a95783          	lhu	a5,74(s2)
    8000567c:	37fd                	addiw	a5,a5,-1
    8000567e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005682:	854a                	mv	a0,s2
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	080080e7          	jalr	128(ra) # 80003704 <iupdate>
  iunlockput(ip);
    8000568c:	854a                	mv	a0,s2
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	3a2080e7          	jalr	930(ra) # 80003a30 <iunlockput>
  end_op();
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	b7a080e7          	jalr	-1158(ra) # 80004210 <end_op>
  return 0;
    8000569e:	4501                	li	a0,0
    800056a0:	a84d                	j	80005752 <sys_unlink+0x1c4>
    end_op();
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	b6e080e7          	jalr	-1170(ra) # 80004210 <end_op>
    return -1;
    800056aa:	557d                	li	a0,-1
    800056ac:	a05d                	j	80005752 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056ae:	00003517          	auipc	a0,0x3
    800056b2:	0ba50513          	addi	a0,a0,186 # 80008768 <syscalls+0x2c0>
    800056b6:	ffffb097          	auipc	ra,0xffffb
    800056ba:	e8e080e7          	jalr	-370(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056be:	04c92703          	lw	a4,76(s2)
    800056c2:	02000793          	li	a5,32
    800056c6:	f6e7f9e3          	bgeu	a5,a4,80005638 <sys_unlink+0xaa>
    800056ca:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ce:	4741                	li	a4,16
    800056d0:	86ce                	mv	a3,s3
    800056d2:	f1840613          	addi	a2,s0,-232
    800056d6:	4581                	li	a1,0
    800056d8:	854a                	mv	a0,s2
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	3a8080e7          	jalr	936(ra) # 80003a82 <readi>
    800056e2:	47c1                	li	a5,16
    800056e4:	00f51b63          	bne	a0,a5,800056fa <sys_unlink+0x16c>
    if(de.inum != 0)
    800056e8:	f1845783          	lhu	a5,-232(s0)
    800056ec:	e7a1                	bnez	a5,80005734 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ee:	29c1                	addiw	s3,s3,16
    800056f0:	04c92783          	lw	a5,76(s2)
    800056f4:	fcf9ede3          	bltu	s3,a5,800056ce <sys_unlink+0x140>
    800056f8:	b781                	j	80005638 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056fa:	00003517          	auipc	a0,0x3
    800056fe:	08650513          	addi	a0,a0,134 # 80008780 <syscalls+0x2d8>
    80005702:	ffffb097          	auipc	ra,0xffffb
    80005706:	e42080e7          	jalr	-446(ra) # 80000544 <panic>
    panic("unlink: writei");
    8000570a:	00003517          	auipc	a0,0x3
    8000570e:	08e50513          	addi	a0,a0,142 # 80008798 <syscalls+0x2f0>
    80005712:	ffffb097          	auipc	ra,0xffffb
    80005716:	e32080e7          	jalr	-462(ra) # 80000544 <panic>
    dp->nlink--;
    8000571a:	04a4d783          	lhu	a5,74(s1)
    8000571e:	37fd                	addiw	a5,a5,-1
    80005720:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005724:	8526                	mv	a0,s1
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	fde080e7          	jalr	-34(ra) # 80003704 <iupdate>
    8000572e:	b781                	j	8000566e <sys_unlink+0xe0>
    return -1;
    80005730:	557d                	li	a0,-1
    80005732:	a005                	j	80005752 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005734:	854a                	mv	a0,s2
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	2fa080e7          	jalr	762(ra) # 80003a30 <iunlockput>
  iunlockput(dp);
    8000573e:	8526                	mv	a0,s1
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	2f0080e7          	jalr	752(ra) # 80003a30 <iunlockput>
  end_op();
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	ac8080e7          	jalr	-1336(ra) # 80004210 <end_op>
  return -1;
    80005750:	557d                	li	a0,-1
}
    80005752:	70ae                	ld	ra,232(sp)
    80005754:	740e                	ld	s0,224(sp)
    80005756:	64ee                	ld	s1,216(sp)
    80005758:	694e                	ld	s2,208(sp)
    8000575a:	69ae                	ld	s3,200(sp)
    8000575c:	616d                	addi	sp,sp,240
    8000575e:	8082                	ret

0000000080005760 <sys_open>:

uint64
sys_open(void)
{
    80005760:	7131                	addi	sp,sp,-192
    80005762:	fd06                	sd	ra,184(sp)
    80005764:	f922                	sd	s0,176(sp)
    80005766:	f526                	sd	s1,168(sp)
    80005768:	f14a                	sd	s2,160(sp)
    8000576a:	ed4e                	sd	s3,152(sp)
    8000576c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000576e:	f4c40593          	addi	a1,s0,-180
    80005772:	4505                	li	a0,1
    80005774:	ffffd097          	auipc	ra,0xffffd
    80005778:	4ac080e7          	jalr	1196(ra) # 80002c20 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000577c:	08000613          	li	a2,128
    80005780:	f5040593          	addi	a1,s0,-176
    80005784:	4501                	li	a0,0
    80005786:	ffffd097          	auipc	ra,0xffffd
    8000578a:	4da080e7          	jalr	1242(ra) # 80002c60 <argstr>
    8000578e:	87aa                	mv	a5,a0
    return -1;
    80005790:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005792:	0a07c963          	bltz	a5,80005844 <sys_open+0xe4>

  begin_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	9fa080e7          	jalr	-1542(ra) # 80004190 <begin_op>

  if(omode & O_CREATE){
    8000579e:	f4c42783          	lw	a5,-180(s0)
    800057a2:	2007f793          	andi	a5,a5,512
    800057a6:	cfc5                	beqz	a5,8000585e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057a8:	4681                	li	a3,0
    800057aa:	4601                	li	a2,0
    800057ac:	4589                	li	a1,2
    800057ae:	f5040513          	addi	a0,s0,-176
    800057b2:	00000097          	auipc	ra,0x0
    800057b6:	974080e7          	jalr	-1676(ra) # 80005126 <create>
    800057ba:	84aa                	mv	s1,a0
    if(ip == 0){
    800057bc:	c959                	beqz	a0,80005852 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057be:	04449703          	lh	a4,68(s1)
    800057c2:	478d                	li	a5,3
    800057c4:	00f71763          	bne	a4,a5,800057d2 <sys_open+0x72>
    800057c8:	0464d703          	lhu	a4,70(s1)
    800057cc:	47a5                	li	a5,9
    800057ce:	0ce7ed63          	bltu	a5,a4,800058a8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	dce080e7          	jalr	-562(ra) # 800045a0 <filealloc>
    800057da:	89aa                	mv	s3,a0
    800057dc:	10050363          	beqz	a0,800058e2 <sys_open+0x182>
    800057e0:	00000097          	auipc	ra,0x0
    800057e4:	904080e7          	jalr	-1788(ra) # 800050e4 <fdalloc>
    800057e8:	892a                	mv	s2,a0
    800057ea:	0e054763          	bltz	a0,800058d8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ee:	04449703          	lh	a4,68(s1)
    800057f2:	478d                	li	a5,3
    800057f4:	0cf70563          	beq	a4,a5,800058be <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057f8:	4789                	li	a5,2
    800057fa:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057fe:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005802:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005806:	f4c42783          	lw	a5,-180(s0)
    8000580a:	0017c713          	xori	a4,a5,1
    8000580e:	8b05                	andi	a4,a4,1
    80005810:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005814:	0037f713          	andi	a4,a5,3
    80005818:	00e03733          	snez	a4,a4
    8000581c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005820:	4007f793          	andi	a5,a5,1024
    80005824:	c791                	beqz	a5,80005830 <sys_open+0xd0>
    80005826:	04449703          	lh	a4,68(s1)
    8000582a:	4789                	li	a5,2
    8000582c:	0af70063          	beq	a4,a5,800058cc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005830:	8526                	mv	a0,s1
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	05e080e7          	jalr	94(ra) # 80003890 <iunlock>
  end_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	9d6080e7          	jalr	-1578(ra) # 80004210 <end_op>

  return fd;
    80005842:	854a                	mv	a0,s2
}
    80005844:	70ea                	ld	ra,184(sp)
    80005846:	744a                	ld	s0,176(sp)
    80005848:	74aa                	ld	s1,168(sp)
    8000584a:	790a                	ld	s2,160(sp)
    8000584c:	69ea                	ld	s3,152(sp)
    8000584e:	6129                	addi	sp,sp,192
    80005850:	8082                	ret
      end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	9be080e7          	jalr	-1602(ra) # 80004210 <end_op>
      return -1;
    8000585a:	557d                	li	a0,-1
    8000585c:	b7e5                	j	80005844 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000585e:	f5040513          	addi	a0,s0,-176
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	712080e7          	jalr	1810(ra) # 80003f74 <namei>
    8000586a:	84aa                	mv	s1,a0
    8000586c:	c905                	beqz	a0,8000589c <sys_open+0x13c>
    ilock(ip);
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	f60080e7          	jalr	-160(ra) # 800037ce <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005876:	04449703          	lh	a4,68(s1)
    8000587a:	4785                	li	a5,1
    8000587c:	f4f711e3          	bne	a4,a5,800057be <sys_open+0x5e>
    80005880:	f4c42783          	lw	a5,-180(s0)
    80005884:	d7b9                	beqz	a5,800057d2 <sys_open+0x72>
      iunlockput(ip);
    80005886:	8526                	mv	a0,s1
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	1a8080e7          	jalr	424(ra) # 80003a30 <iunlockput>
      end_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	980080e7          	jalr	-1664(ra) # 80004210 <end_op>
      return -1;
    80005898:	557d                	li	a0,-1
    8000589a:	b76d                	j	80005844 <sys_open+0xe4>
      end_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	974080e7          	jalr	-1676(ra) # 80004210 <end_op>
      return -1;
    800058a4:	557d                	li	a0,-1
    800058a6:	bf79                	j	80005844 <sys_open+0xe4>
    iunlockput(ip);
    800058a8:	8526                	mv	a0,s1
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	186080e7          	jalr	390(ra) # 80003a30 <iunlockput>
    end_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	95e080e7          	jalr	-1698(ra) # 80004210 <end_op>
    return -1;
    800058ba:	557d                	li	a0,-1
    800058bc:	b761                	j	80005844 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058be:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058c2:	04649783          	lh	a5,70(s1)
    800058c6:	02f99223          	sh	a5,36(s3)
    800058ca:	bf25                	j	80005802 <sys_open+0xa2>
    itrunc(ip);
    800058cc:	8526                	mv	a0,s1
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	00e080e7          	jalr	14(ra) # 800038dc <itrunc>
    800058d6:	bfa9                	j	80005830 <sys_open+0xd0>
      fileclose(f);
    800058d8:	854e                	mv	a0,s3
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	d82080e7          	jalr	-638(ra) # 8000465c <fileclose>
    iunlockput(ip);
    800058e2:	8526                	mv	a0,s1
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	14c080e7          	jalr	332(ra) # 80003a30 <iunlockput>
    end_op();
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	924080e7          	jalr	-1756(ra) # 80004210 <end_op>
    return -1;
    800058f4:	557d                	li	a0,-1
    800058f6:	b7b9                	j	80005844 <sys_open+0xe4>

00000000800058f8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058f8:	7175                	addi	sp,sp,-144
    800058fa:	e506                	sd	ra,136(sp)
    800058fc:	e122                	sd	s0,128(sp)
    800058fe:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	890080e7          	jalr	-1904(ra) # 80004190 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005908:	08000613          	li	a2,128
    8000590c:	f7040593          	addi	a1,s0,-144
    80005910:	4501                	li	a0,0
    80005912:	ffffd097          	auipc	ra,0xffffd
    80005916:	34e080e7          	jalr	846(ra) # 80002c60 <argstr>
    8000591a:	02054963          	bltz	a0,8000594c <sys_mkdir+0x54>
    8000591e:	4681                	li	a3,0
    80005920:	4601                	li	a2,0
    80005922:	4585                	li	a1,1
    80005924:	f7040513          	addi	a0,s0,-144
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	7fe080e7          	jalr	2046(ra) # 80005126 <create>
    80005930:	cd11                	beqz	a0,8000594c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	0fe080e7          	jalr	254(ra) # 80003a30 <iunlockput>
  end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	8d6080e7          	jalr	-1834(ra) # 80004210 <end_op>
  return 0;
    80005942:	4501                	li	a0,0
}
    80005944:	60aa                	ld	ra,136(sp)
    80005946:	640a                	ld	s0,128(sp)
    80005948:	6149                	addi	sp,sp,144
    8000594a:	8082                	ret
    end_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	8c4080e7          	jalr	-1852(ra) # 80004210 <end_op>
    return -1;
    80005954:	557d                	li	a0,-1
    80005956:	b7fd                	j	80005944 <sys_mkdir+0x4c>

0000000080005958 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005958:	7135                	addi	sp,sp,-160
    8000595a:	ed06                	sd	ra,152(sp)
    8000595c:	e922                	sd	s0,144(sp)
    8000595e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	830080e7          	jalr	-2000(ra) # 80004190 <begin_op>
  argint(1, &major);
    80005968:	f6c40593          	addi	a1,s0,-148
    8000596c:	4505                	li	a0,1
    8000596e:	ffffd097          	auipc	ra,0xffffd
    80005972:	2b2080e7          	jalr	690(ra) # 80002c20 <argint>
  argint(2, &minor);
    80005976:	f6840593          	addi	a1,s0,-152
    8000597a:	4509                	li	a0,2
    8000597c:	ffffd097          	auipc	ra,0xffffd
    80005980:	2a4080e7          	jalr	676(ra) # 80002c20 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005984:	08000613          	li	a2,128
    80005988:	f7040593          	addi	a1,s0,-144
    8000598c:	4501                	li	a0,0
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	2d2080e7          	jalr	722(ra) # 80002c60 <argstr>
    80005996:	02054b63          	bltz	a0,800059cc <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000599a:	f6841683          	lh	a3,-152(s0)
    8000599e:	f6c41603          	lh	a2,-148(s0)
    800059a2:	458d                	li	a1,3
    800059a4:	f7040513          	addi	a0,s0,-144
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	77e080e7          	jalr	1918(ra) # 80005126 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059b0:	cd11                	beqz	a0,800059cc <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	07e080e7          	jalr	126(ra) # 80003a30 <iunlockput>
  end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	856080e7          	jalr	-1962(ra) # 80004210 <end_op>
  return 0;
    800059c2:	4501                	li	a0,0
}
    800059c4:	60ea                	ld	ra,152(sp)
    800059c6:	644a                	ld	s0,144(sp)
    800059c8:	610d                	addi	sp,sp,160
    800059ca:	8082                	ret
    end_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	844080e7          	jalr	-1980(ra) # 80004210 <end_op>
    return -1;
    800059d4:	557d                	li	a0,-1
    800059d6:	b7fd                	j	800059c4 <sys_mknod+0x6c>

00000000800059d8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059d8:	7135                	addi	sp,sp,-160
    800059da:	ed06                	sd	ra,152(sp)
    800059dc:	e922                	sd	s0,144(sp)
    800059de:	e526                	sd	s1,136(sp)
    800059e0:	e14a                	sd	s2,128(sp)
    800059e2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059e4:	ffffc097          	auipc	ra,0xffffc
    800059e8:	fe2080e7          	jalr	-30(ra) # 800019c6 <myproc>
    800059ec:	892a                	mv	s2,a0
  
  begin_op();
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	7a2080e7          	jalr	1954(ra) # 80004190 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059f6:	08000613          	li	a2,128
    800059fa:	f6040593          	addi	a1,s0,-160
    800059fe:	4501                	li	a0,0
    80005a00:	ffffd097          	auipc	ra,0xffffd
    80005a04:	260080e7          	jalr	608(ra) # 80002c60 <argstr>
    80005a08:	04054b63          	bltz	a0,80005a5e <sys_chdir+0x86>
    80005a0c:	f6040513          	addi	a0,s0,-160
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	564080e7          	jalr	1380(ra) # 80003f74 <namei>
    80005a18:	84aa                	mv	s1,a0
    80005a1a:	c131                	beqz	a0,80005a5e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	db2080e7          	jalr	-590(ra) # 800037ce <ilock>
  if(ip->type != T_DIR){
    80005a24:	04449703          	lh	a4,68(s1)
    80005a28:	4785                	li	a5,1
    80005a2a:	04f71063          	bne	a4,a5,80005a6a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a2e:	8526                	mv	a0,s1
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	e60080e7          	jalr	-416(ra) # 80003890 <iunlock>
  iput(p->cwd);
    80005a38:	16093503          	ld	a0,352(s2)
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	f4c080e7          	jalr	-180(ra) # 80003988 <iput>
  end_op();
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	7cc080e7          	jalr	1996(ra) # 80004210 <end_op>
  p->cwd = ip;
    80005a4c:	16993023          	sd	s1,352(s2)
  return 0;
    80005a50:	4501                	li	a0,0
}
    80005a52:	60ea                	ld	ra,152(sp)
    80005a54:	644a                	ld	s0,144(sp)
    80005a56:	64aa                	ld	s1,136(sp)
    80005a58:	690a                	ld	s2,128(sp)
    80005a5a:	610d                	addi	sp,sp,160
    80005a5c:	8082                	ret
    end_op();
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	7b2080e7          	jalr	1970(ra) # 80004210 <end_op>
    return -1;
    80005a66:	557d                	li	a0,-1
    80005a68:	b7ed                	j	80005a52 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a6a:	8526                	mv	a0,s1
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	fc4080e7          	jalr	-60(ra) # 80003a30 <iunlockput>
    end_op();
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	79c080e7          	jalr	1948(ra) # 80004210 <end_op>
    return -1;
    80005a7c:	557d                	li	a0,-1
    80005a7e:	bfd1                	j	80005a52 <sys_chdir+0x7a>

0000000080005a80 <sys_exec>:

uint64
sys_exec(void)
{
    80005a80:	7145                	addi	sp,sp,-464
    80005a82:	e786                	sd	ra,456(sp)
    80005a84:	e3a2                	sd	s0,448(sp)
    80005a86:	ff26                	sd	s1,440(sp)
    80005a88:	fb4a                	sd	s2,432(sp)
    80005a8a:	f74e                	sd	s3,424(sp)
    80005a8c:	f352                	sd	s4,416(sp)
    80005a8e:	ef56                	sd	s5,408(sp)
    80005a90:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a92:	e3840593          	addi	a1,s0,-456
    80005a96:	4505                	li	a0,1
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	1a8080e7          	jalr	424(ra) # 80002c40 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005aa0:	08000613          	li	a2,128
    80005aa4:	f4040593          	addi	a1,s0,-192
    80005aa8:	4501                	li	a0,0
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	1b6080e7          	jalr	438(ra) # 80002c60 <argstr>
    80005ab2:	87aa                	mv	a5,a0
    return -1;
    80005ab4:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ab6:	0c07c263          	bltz	a5,80005b7a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005aba:	10000613          	li	a2,256
    80005abe:	4581                	li	a1,0
    80005ac0:	e4040513          	addi	a0,s0,-448
    80005ac4:	ffffb097          	auipc	ra,0xffffb
    80005ac8:	222080e7          	jalr	546(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005acc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ad0:	89a6                	mv	s3,s1
    80005ad2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ad4:	02000a13          	li	s4,32
    80005ad8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005adc:	00391513          	slli	a0,s2,0x3
    80005ae0:	e3040593          	addi	a1,s0,-464
    80005ae4:	e3843783          	ld	a5,-456(s0)
    80005ae8:	953e                	add	a0,a0,a5
    80005aea:	ffffd097          	auipc	ra,0xffffd
    80005aee:	098080e7          	jalr	152(ra) # 80002b82 <fetchaddr>
    80005af2:	02054a63          	bltz	a0,80005b26 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005af6:	e3043783          	ld	a5,-464(s0)
    80005afa:	c3b9                	beqz	a5,80005b40 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005afc:	ffffb097          	auipc	ra,0xffffb
    80005b00:	ffe080e7          	jalr	-2(ra) # 80000afa <kalloc>
    80005b04:	85aa                	mv	a1,a0
    80005b06:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b0a:	cd11                	beqz	a0,80005b26 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b0c:	6605                	lui	a2,0x1
    80005b0e:	e3043503          	ld	a0,-464(s0)
    80005b12:	ffffd097          	auipc	ra,0xffffd
    80005b16:	0c2080e7          	jalr	194(ra) # 80002bd4 <fetchstr>
    80005b1a:	00054663          	bltz	a0,80005b26 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b1e:	0905                	addi	s2,s2,1
    80005b20:	09a1                	addi	s3,s3,8
    80005b22:	fb491be3          	bne	s2,s4,80005ad8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b26:	10048913          	addi	s2,s1,256
    80005b2a:	6088                	ld	a0,0(s1)
    80005b2c:	c531                	beqz	a0,80005b78 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b2e:	ffffb097          	auipc	ra,0xffffb
    80005b32:	ed0080e7          	jalr	-304(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b36:	04a1                	addi	s1,s1,8
    80005b38:	ff2499e3          	bne	s1,s2,80005b2a <sys_exec+0xaa>
  return -1;
    80005b3c:	557d                	li	a0,-1
    80005b3e:	a835                	j	80005b7a <sys_exec+0xfa>
      argv[i] = 0;
    80005b40:	0a8e                	slli	s5,s5,0x3
    80005b42:	fc040793          	addi	a5,s0,-64
    80005b46:	9abe                	add	s5,s5,a5
    80005b48:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b4c:	e4040593          	addi	a1,s0,-448
    80005b50:	f4040513          	addi	a0,s0,-192
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	190080e7          	jalr	400(ra) # 80004ce4 <exec>
    80005b5c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b5e:	10048993          	addi	s3,s1,256
    80005b62:	6088                	ld	a0,0(s1)
    80005b64:	c901                	beqz	a0,80005b74 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b66:	ffffb097          	auipc	ra,0xffffb
    80005b6a:	e98080e7          	jalr	-360(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b6e:	04a1                	addi	s1,s1,8
    80005b70:	ff3499e3          	bne	s1,s3,80005b62 <sys_exec+0xe2>
  return ret;
    80005b74:	854a                	mv	a0,s2
    80005b76:	a011                	j	80005b7a <sys_exec+0xfa>
  return -1;
    80005b78:	557d                	li	a0,-1
}
    80005b7a:	60be                	ld	ra,456(sp)
    80005b7c:	641e                	ld	s0,448(sp)
    80005b7e:	74fa                	ld	s1,440(sp)
    80005b80:	795a                	ld	s2,432(sp)
    80005b82:	79ba                	ld	s3,424(sp)
    80005b84:	7a1a                	ld	s4,416(sp)
    80005b86:	6afa                	ld	s5,408(sp)
    80005b88:	6179                	addi	sp,sp,464
    80005b8a:	8082                	ret

0000000080005b8c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b8c:	7139                	addi	sp,sp,-64
    80005b8e:	fc06                	sd	ra,56(sp)
    80005b90:	f822                	sd	s0,48(sp)
    80005b92:	f426                	sd	s1,40(sp)
    80005b94:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b96:	ffffc097          	auipc	ra,0xffffc
    80005b9a:	e30080e7          	jalr	-464(ra) # 800019c6 <myproc>
    80005b9e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ba0:	fd840593          	addi	a1,s0,-40
    80005ba4:	4501                	li	a0,0
    80005ba6:	ffffd097          	auipc	ra,0xffffd
    80005baa:	09a080e7          	jalr	154(ra) # 80002c40 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005bae:	fc840593          	addi	a1,s0,-56
    80005bb2:	fd040513          	addi	a0,s0,-48
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	dd6080e7          	jalr	-554(ra) # 8000498c <pipealloc>
    return -1;
    80005bbe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bc0:	0c054463          	bltz	a0,80005c88 <sys_pipe+0xfc>
  fd0 = -1;
    80005bc4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bc8:	fd043503          	ld	a0,-48(s0)
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	518080e7          	jalr	1304(ra) # 800050e4 <fdalloc>
    80005bd4:	fca42223          	sw	a0,-60(s0)
    80005bd8:	08054b63          	bltz	a0,80005c6e <sys_pipe+0xe2>
    80005bdc:	fc843503          	ld	a0,-56(s0)
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	504080e7          	jalr	1284(ra) # 800050e4 <fdalloc>
    80005be8:	fca42023          	sw	a0,-64(s0)
    80005bec:	06054863          	bltz	a0,80005c5c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf0:	4691                	li	a3,4
    80005bf2:	fc440613          	addi	a2,s0,-60
    80005bf6:	fd843583          	ld	a1,-40(s0)
    80005bfa:	70a8                	ld	a0,96(s1)
    80005bfc:	ffffc097          	auipc	ra,0xffffc
    80005c00:	a88080e7          	jalr	-1400(ra) # 80001684 <copyout>
    80005c04:	02054063          	bltz	a0,80005c24 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c08:	4691                	li	a3,4
    80005c0a:	fc040613          	addi	a2,s0,-64
    80005c0e:	fd843583          	ld	a1,-40(s0)
    80005c12:	0591                	addi	a1,a1,4
    80005c14:	70a8                	ld	a0,96(s1)
    80005c16:	ffffc097          	auipc	ra,0xffffc
    80005c1a:	a6e080e7          	jalr	-1426(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c1e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c20:	06055463          	bgez	a0,80005c88 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c24:	fc442783          	lw	a5,-60(s0)
    80005c28:	07f1                	addi	a5,a5,28
    80005c2a:	078e                	slli	a5,a5,0x3
    80005c2c:	97a6                	add	a5,a5,s1
    80005c2e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c32:	fc042503          	lw	a0,-64(s0)
    80005c36:	0571                	addi	a0,a0,28
    80005c38:	050e                	slli	a0,a0,0x3
    80005c3a:	94aa                	add	s1,s1,a0
    80005c3c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c40:	fd043503          	ld	a0,-48(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	a18080e7          	jalr	-1512(ra) # 8000465c <fileclose>
    fileclose(wf);
    80005c4c:	fc843503          	ld	a0,-56(s0)
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	a0c080e7          	jalr	-1524(ra) # 8000465c <fileclose>
    return -1;
    80005c58:	57fd                	li	a5,-1
    80005c5a:	a03d                	j	80005c88 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c5c:	fc442783          	lw	a5,-60(s0)
    80005c60:	0007c763          	bltz	a5,80005c6e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c64:	07f1                	addi	a5,a5,28
    80005c66:	078e                	slli	a5,a5,0x3
    80005c68:	94be                	add	s1,s1,a5
    80005c6a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c6e:	fd043503          	ld	a0,-48(s0)
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	9ea080e7          	jalr	-1558(ra) # 8000465c <fileclose>
    fileclose(wf);
    80005c7a:	fc843503          	ld	a0,-56(s0)
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	9de080e7          	jalr	-1570(ra) # 8000465c <fileclose>
    return -1;
    80005c86:	57fd                	li	a5,-1
}
    80005c88:	853e                	mv	a0,a5
    80005c8a:	70e2                	ld	ra,56(sp)
    80005c8c:	7442                	ld	s0,48(sp)
    80005c8e:	74a2                	ld	s1,40(sp)
    80005c90:	6121                	addi	sp,sp,64
    80005c92:	8082                	ret
	...

0000000080005ca0 <kernelvec>:
    80005ca0:	7111                	addi	sp,sp,-256
    80005ca2:	e006                	sd	ra,0(sp)
    80005ca4:	e40a                	sd	sp,8(sp)
    80005ca6:	e80e                	sd	gp,16(sp)
    80005ca8:	ec12                	sd	tp,24(sp)
    80005caa:	f016                	sd	t0,32(sp)
    80005cac:	f41a                	sd	t1,40(sp)
    80005cae:	f81e                	sd	t2,48(sp)
    80005cb0:	fc22                	sd	s0,56(sp)
    80005cb2:	e0a6                	sd	s1,64(sp)
    80005cb4:	e4aa                	sd	a0,72(sp)
    80005cb6:	e8ae                	sd	a1,80(sp)
    80005cb8:	ecb2                	sd	a2,88(sp)
    80005cba:	f0b6                	sd	a3,96(sp)
    80005cbc:	f4ba                	sd	a4,104(sp)
    80005cbe:	f8be                	sd	a5,112(sp)
    80005cc0:	fcc2                	sd	a6,120(sp)
    80005cc2:	e146                	sd	a7,128(sp)
    80005cc4:	e54a                	sd	s2,136(sp)
    80005cc6:	e94e                	sd	s3,144(sp)
    80005cc8:	ed52                	sd	s4,152(sp)
    80005cca:	f156                	sd	s5,160(sp)
    80005ccc:	f55a                	sd	s6,168(sp)
    80005cce:	f95e                	sd	s7,176(sp)
    80005cd0:	fd62                	sd	s8,184(sp)
    80005cd2:	e1e6                	sd	s9,192(sp)
    80005cd4:	e5ea                	sd	s10,200(sp)
    80005cd6:	e9ee                	sd	s11,208(sp)
    80005cd8:	edf2                	sd	t3,216(sp)
    80005cda:	f1f6                	sd	t4,224(sp)
    80005cdc:	f5fa                	sd	t5,232(sp)
    80005cde:	f9fe                	sd	t6,240(sp)
    80005ce0:	d6ffc0ef          	jal	ra,80002a4e <kerneltrap>
    80005ce4:	6082                	ld	ra,0(sp)
    80005ce6:	6122                	ld	sp,8(sp)
    80005ce8:	61c2                	ld	gp,16(sp)
    80005cea:	7282                	ld	t0,32(sp)
    80005cec:	7322                	ld	t1,40(sp)
    80005cee:	73c2                	ld	t2,48(sp)
    80005cf0:	7462                	ld	s0,56(sp)
    80005cf2:	6486                	ld	s1,64(sp)
    80005cf4:	6526                	ld	a0,72(sp)
    80005cf6:	65c6                	ld	a1,80(sp)
    80005cf8:	6666                	ld	a2,88(sp)
    80005cfa:	7686                	ld	a3,96(sp)
    80005cfc:	7726                	ld	a4,104(sp)
    80005cfe:	77c6                	ld	a5,112(sp)
    80005d00:	7866                	ld	a6,120(sp)
    80005d02:	688a                	ld	a7,128(sp)
    80005d04:	692a                	ld	s2,136(sp)
    80005d06:	69ca                	ld	s3,144(sp)
    80005d08:	6a6a                	ld	s4,152(sp)
    80005d0a:	7a8a                	ld	s5,160(sp)
    80005d0c:	7b2a                	ld	s6,168(sp)
    80005d0e:	7bca                	ld	s7,176(sp)
    80005d10:	7c6a                	ld	s8,184(sp)
    80005d12:	6c8e                	ld	s9,192(sp)
    80005d14:	6d2e                	ld	s10,200(sp)
    80005d16:	6dce                	ld	s11,208(sp)
    80005d18:	6e6e                	ld	t3,216(sp)
    80005d1a:	7e8e                	ld	t4,224(sp)
    80005d1c:	7f2e                	ld	t5,232(sp)
    80005d1e:	7fce                	ld	t6,240(sp)
    80005d20:	6111                	addi	sp,sp,256
    80005d22:	10200073          	sret
    80005d26:	00000013          	nop
    80005d2a:	00000013          	nop
    80005d2e:	0001                	nop

0000000080005d30 <timervec>:
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	e10c                	sd	a1,0(a0)
    80005d36:	e510                	sd	a2,8(a0)
    80005d38:	e914                	sd	a3,16(a0)
    80005d3a:	6d0c                	ld	a1,24(a0)
    80005d3c:	7110                	ld	a2,32(a0)
    80005d3e:	6194                	ld	a3,0(a1)
    80005d40:	96b2                	add	a3,a3,a2
    80005d42:	e194                	sd	a3,0(a1)
    80005d44:	4589                	li	a1,2
    80005d46:	14459073          	csrw	sip,a1
    80005d4a:	6914                	ld	a3,16(a0)
    80005d4c:	6510                	ld	a2,8(a0)
    80005d4e:	610c                	ld	a1,0(a0)
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	30200073          	mret
	...

0000000080005d5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d5a:	1141                	addi	sp,sp,-16
    80005d5c:	e422                	sd	s0,8(sp)
    80005d5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d60:	0c0007b7          	lui	a5,0xc000
    80005d64:	4705                	li	a4,1
    80005d66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d68:	c3d8                	sw	a4,4(a5)
}
    80005d6a:	6422                	ld	s0,8(sp)
    80005d6c:	0141                	addi	sp,sp,16
    80005d6e:	8082                	ret

0000000080005d70 <plicinithart>:

void
plicinithart(void)
{
    80005d70:	1141                	addi	sp,sp,-16
    80005d72:	e406                	sd	ra,8(sp)
    80005d74:	e022                	sd	s0,0(sp)
    80005d76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	c22080e7          	jalr	-990(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d80:	0085171b          	slliw	a4,a0,0x8
    80005d84:	0c0027b7          	lui	a5,0xc002
    80005d88:	97ba                	add	a5,a5,a4
    80005d8a:	40200713          	li	a4,1026
    80005d8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d92:	00d5151b          	slliw	a0,a0,0xd
    80005d96:	0c2017b7          	lui	a5,0xc201
    80005d9a:	953e                	add	a0,a0,a5
    80005d9c:	00052023          	sw	zero,0(a0)
}
    80005da0:	60a2                	ld	ra,8(sp)
    80005da2:	6402                	ld	s0,0(sp)
    80005da4:	0141                	addi	sp,sp,16
    80005da6:	8082                	ret

0000000080005da8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005da8:	1141                	addi	sp,sp,-16
    80005daa:	e406                	sd	ra,8(sp)
    80005dac:	e022                	sd	s0,0(sp)
    80005dae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005db0:	ffffc097          	auipc	ra,0xffffc
    80005db4:	bea080e7          	jalr	-1046(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005db8:	00d5179b          	slliw	a5,a0,0xd
    80005dbc:	0c201537          	lui	a0,0xc201
    80005dc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005dc2:	4148                	lw	a0,4(a0)
    80005dc4:	60a2                	ld	ra,8(sp)
    80005dc6:	6402                	ld	s0,0(sp)
    80005dc8:	0141                	addi	sp,sp,16
    80005dca:	8082                	ret

0000000080005dcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dcc:	1101                	addi	sp,sp,-32
    80005dce:	ec06                	sd	ra,24(sp)
    80005dd0:	e822                	sd	s0,16(sp)
    80005dd2:	e426                	sd	s1,8(sp)
    80005dd4:	1000                	addi	s0,sp,32
    80005dd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	bc2080e7          	jalr	-1086(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005de0:	00d5151b          	slliw	a0,a0,0xd
    80005de4:	0c2017b7          	lui	a5,0xc201
    80005de8:	97aa                	add	a5,a5,a0
    80005dea:	c3c4                	sw	s1,4(a5)
}
    80005dec:	60e2                	ld	ra,24(sp)
    80005dee:	6442                	ld	s0,16(sp)
    80005df0:	64a2                	ld	s1,8(sp)
    80005df2:	6105                	addi	sp,sp,32
    80005df4:	8082                	ret

0000000080005df6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005df6:	1141                	addi	sp,sp,-16
    80005df8:	e406                	sd	ra,8(sp)
    80005dfa:	e022                	sd	s0,0(sp)
    80005dfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dfe:	479d                	li	a5,7
    80005e00:	04a7cc63          	blt	a5,a0,80005e58 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e04:	0001c797          	auipc	a5,0x1c
    80005e08:	28c78793          	addi	a5,a5,652 # 80022090 <disk>
    80005e0c:	97aa                	add	a5,a5,a0
    80005e0e:	0187c783          	lbu	a5,24(a5)
    80005e12:	ebb9                	bnez	a5,80005e68 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e14:	00451613          	slli	a2,a0,0x4
    80005e18:	0001c797          	auipc	a5,0x1c
    80005e1c:	27878793          	addi	a5,a5,632 # 80022090 <disk>
    80005e20:	6394                	ld	a3,0(a5)
    80005e22:	96b2                	add	a3,a3,a2
    80005e24:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e28:	6398                	ld	a4,0(a5)
    80005e2a:	9732                	add	a4,a4,a2
    80005e2c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e30:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e34:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e38:	953e                	add	a0,a0,a5
    80005e3a:	4785                	li	a5,1
    80005e3c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e40:	0001c517          	auipc	a0,0x1c
    80005e44:	26850513          	addi	a0,a0,616 # 800220a8 <disk+0x18>
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	2fe080e7          	jalr	766(ra) # 80002146 <wakeup>
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret
    panic("free_desc 1");
    80005e58:	00003517          	auipc	a0,0x3
    80005e5c:	95050513          	addi	a0,a0,-1712 # 800087a8 <syscalls+0x300>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6e4080e7          	jalr	1764(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005e68:	00003517          	auipc	a0,0x3
    80005e6c:	95050513          	addi	a0,a0,-1712 # 800087b8 <syscalls+0x310>
    80005e70:	ffffa097          	auipc	ra,0xffffa
    80005e74:	6d4080e7          	jalr	1748(ra) # 80000544 <panic>

0000000080005e78 <virtio_disk_init>:
{
    80005e78:	1101                	addi	sp,sp,-32
    80005e7a:	ec06                	sd	ra,24(sp)
    80005e7c:	e822                	sd	s0,16(sp)
    80005e7e:	e426                	sd	s1,8(sp)
    80005e80:	e04a                	sd	s2,0(sp)
    80005e82:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e84:	00003597          	auipc	a1,0x3
    80005e88:	94458593          	addi	a1,a1,-1724 # 800087c8 <syscalls+0x320>
    80005e8c:	0001c517          	auipc	a0,0x1c
    80005e90:	32c50513          	addi	a0,a0,812 # 800221b8 <disk+0x128>
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	cc6080e7          	jalr	-826(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e9c:	100017b7          	lui	a5,0x10001
    80005ea0:	4398                	lw	a4,0(a5)
    80005ea2:	2701                	sext.w	a4,a4
    80005ea4:	747277b7          	lui	a5,0x74727
    80005ea8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eac:	14f71e63          	bne	a4,a5,80006008 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005eb0:	100017b7          	lui	a5,0x10001
    80005eb4:	43dc                	lw	a5,4(a5)
    80005eb6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eb8:	4709                	li	a4,2
    80005eba:	14e79763          	bne	a5,a4,80006008 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ebe:	100017b7          	lui	a5,0x10001
    80005ec2:	479c                	lw	a5,8(a5)
    80005ec4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ec6:	14e79163          	bne	a5,a4,80006008 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eca:	100017b7          	lui	a5,0x10001
    80005ece:	47d8                	lw	a4,12(a5)
    80005ed0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ed2:	554d47b7          	lui	a5,0x554d4
    80005ed6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eda:	12f71763          	bne	a4,a5,80006008 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ede:	100017b7          	lui	a5,0x10001
    80005ee2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee6:	4705                	li	a4,1
    80005ee8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eea:	470d                	li	a4,3
    80005eec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ef0:	c7ffe737          	lui	a4,0xc7ffe
    80005ef4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc58f>
    80005ef8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005efa:	2701                	sext.w	a4,a4
    80005efc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efe:	472d                	li	a4,11
    80005f00:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f02:	0707a903          	lw	s2,112(a5)
    80005f06:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f08:	00897793          	andi	a5,s2,8
    80005f0c:	10078663          	beqz	a5,80006018 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f10:	100017b7          	lui	a5,0x10001
    80005f14:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f18:	43fc                	lw	a5,68(a5)
    80005f1a:	2781                	sext.w	a5,a5
    80005f1c:	10079663          	bnez	a5,80006028 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f20:	100017b7          	lui	a5,0x10001
    80005f24:	5bdc                	lw	a5,52(a5)
    80005f26:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f28:	10078863          	beqz	a5,80006038 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005f2c:	471d                	li	a4,7
    80005f2e:	10f77d63          	bgeu	a4,a5,80006048 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005f32:	ffffb097          	auipc	ra,0xffffb
    80005f36:	bc8080e7          	jalr	-1080(ra) # 80000afa <kalloc>
    80005f3a:	0001c497          	auipc	s1,0x1c
    80005f3e:	15648493          	addi	s1,s1,342 # 80022090 <disk>
    80005f42:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f44:	ffffb097          	auipc	ra,0xffffb
    80005f48:	bb6080e7          	jalr	-1098(ra) # 80000afa <kalloc>
    80005f4c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	bac080e7          	jalr	-1108(ra) # 80000afa <kalloc>
    80005f56:	87aa                	mv	a5,a0
    80005f58:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f5a:	6088                	ld	a0,0(s1)
    80005f5c:	cd75                	beqz	a0,80006058 <virtio_disk_init+0x1e0>
    80005f5e:	0001c717          	auipc	a4,0x1c
    80005f62:	13a73703          	ld	a4,314(a4) # 80022098 <disk+0x8>
    80005f66:	cb6d                	beqz	a4,80006058 <virtio_disk_init+0x1e0>
    80005f68:	cbe5                	beqz	a5,80006058 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005f6a:	6605                	lui	a2,0x1
    80005f6c:	4581                	li	a1,0
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	d78080e7          	jalr	-648(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f76:	0001c497          	auipc	s1,0x1c
    80005f7a:	11a48493          	addi	s1,s1,282 # 80022090 <disk>
    80005f7e:	6605                	lui	a2,0x1
    80005f80:	4581                	li	a1,0
    80005f82:	6488                	ld	a0,8(s1)
    80005f84:	ffffb097          	auipc	ra,0xffffb
    80005f88:	d62080e7          	jalr	-670(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f8c:	6605                	lui	a2,0x1
    80005f8e:	4581                	li	a1,0
    80005f90:	6888                	ld	a0,16(s1)
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	d54080e7          	jalr	-684(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f9a:	100017b7          	lui	a5,0x10001
    80005f9e:	4721                	li	a4,8
    80005fa0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fa2:	4098                	lw	a4,0(s1)
    80005fa4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005fa8:	40d8                	lw	a4,4(s1)
    80005faa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005fae:	6498                	ld	a4,8(s1)
    80005fb0:	0007069b          	sext.w	a3,a4
    80005fb4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fb8:	9701                	srai	a4,a4,0x20
    80005fba:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fbe:	6898                	ld	a4,16(s1)
    80005fc0:	0007069b          	sext.w	a3,a4
    80005fc4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fc8:	9701                	srai	a4,a4,0x20
    80005fca:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fce:	4685                	li	a3,1
    80005fd0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005fd2:	4705                	li	a4,1
    80005fd4:	00d48c23          	sb	a3,24(s1)
    80005fd8:	00e48ca3          	sb	a4,25(s1)
    80005fdc:	00e48d23          	sb	a4,26(s1)
    80005fe0:	00e48da3          	sb	a4,27(s1)
    80005fe4:	00e48e23          	sb	a4,28(s1)
    80005fe8:	00e48ea3          	sb	a4,29(s1)
    80005fec:	00e48f23          	sb	a4,30(s1)
    80005ff0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005ff4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff8:	0727a823          	sw	s2,112(a5)
}
    80005ffc:	60e2                	ld	ra,24(sp)
    80005ffe:	6442                	ld	s0,16(sp)
    80006000:	64a2                	ld	s1,8(sp)
    80006002:	6902                	ld	s2,0(sp)
    80006004:	6105                	addi	sp,sp,32
    80006006:	8082                	ret
    panic("could not find virtio disk");
    80006008:	00002517          	auipc	a0,0x2
    8000600c:	7d050513          	addi	a0,a0,2000 # 800087d8 <syscalls+0x330>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	534080e7          	jalr	1332(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006018:	00002517          	auipc	a0,0x2
    8000601c:	7e050513          	addi	a0,a0,2016 # 800087f8 <syscalls+0x350>
    80006020:	ffffa097          	auipc	ra,0xffffa
    80006024:	524080e7          	jalr	1316(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006028:	00002517          	auipc	a0,0x2
    8000602c:	7f050513          	addi	a0,a0,2032 # 80008818 <syscalls+0x370>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	514080e7          	jalr	1300(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006038:	00003517          	auipc	a0,0x3
    8000603c:	80050513          	addi	a0,a0,-2048 # 80008838 <syscalls+0x390>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	504080e7          	jalr	1284(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006048:	00003517          	auipc	a0,0x3
    8000604c:	81050513          	addi	a0,a0,-2032 # 80008858 <syscalls+0x3b0>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4f4080e7          	jalr	1268(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006058:	00003517          	auipc	a0,0x3
    8000605c:	82050513          	addi	a0,a0,-2016 # 80008878 <syscalls+0x3d0>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4e4080e7          	jalr	1252(ra) # 80000544 <panic>

0000000080006068 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006068:	7159                	addi	sp,sp,-112
    8000606a:	f486                	sd	ra,104(sp)
    8000606c:	f0a2                	sd	s0,96(sp)
    8000606e:	eca6                	sd	s1,88(sp)
    80006070:	e8ca                	sd	s2,80(sp)
    80006072:	e4ce                	sd	s3,72(sp)
    80006074:	e0d2                	sd	s4,64(sp)
    80006076:	fc56                	sd	s5,56(sp)
    80006078:	f85a                	sd	s6,48(sp)
    8000607a:	f45e                	sd	s7,40(sp)
    8000607c:	f062                	sd	s8,32(sp)
    8000607e:	ec66                	sd	s9,24(sp)
    80006080:	e86a                	sd	s10,16(sp)
    80006082:	1880                	addi	s0,sp,112
    80006084:	892a                	mv	s2,a0
    80006086:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006088:	00c52c83          	lw	s9,12(a0)
    8000608c:	001c9c9b          	slliw	s9,s9,0x1
    80006090:	1c82                	slli	s9,s9,0x20
    80006092:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006096:	0001c517          	auipc	a0,0x1c
    8000609a:	12250513          	addi	a0,a0,290 # 800221b8 <disk+0x128>
    8000609e:	ffffb097          	auipc	ra,0xffffb
    800060a2:	b4c080e7          	jalr	-1204(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800060a6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060a8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800060aa:	0001cb17          	auipc	s6,0x1c
    800060ae:	fe6b0b13          	addi	s6,s6,-26 # 80022090 <disk>
  for(int i = 0; i < 3; i++){
    800060b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060b4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060b6:	0001cc17          	auipc	s8,0x1c
    800060ba:	102c0c13          	addi	s8,s8,258 # 800221b8 <disk+0x128>
    800060be:	a8b5                	j	8000613a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800060c0:	00fb06b3          	add	a3,s6,a5
    800060c4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060c8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060ca:	0207c563          	bltz	a5,800060f4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060ce:	2485                	addiw	s1,s1,1
    800060d0:	0711                	addi	a4,a4,4
    800060d2:	1f548a63          	beq	s1,s5,800062c6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800060d6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060d8:	0001c697          	auipc	a3,0x1c
    800060dc:	fb868693          	addi	a3,a3,-72 # 80022090 <disk>
    800060e0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060e2:	0186c583          	lbu	a1,24(a3)
    800060e6:	fde9                	bnez	a1,800060c0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060e8:	2785                	addiw	a5,a5,1
    800060ea:	0685                	addi	a3,a3,1
    800060ec:	ff779be3          	bne	a5,s7,800060e2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060f0:	57fd                	li	a5,-1
    800060f2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060f4:	02905a63          	blez	s1,80006128 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060f8:	f9042503          	lw	a0,-112(s0)
    800060fc:	00000097          	auipc	ra,0x0
    80006100:	cfa080e7          	jalr	-774(ra) # 80005df6 <free_desc>
      for(int j = 0; j < i; j++)
    80006104:	4785                	li	a5,1
    80006106:	0297d163          	bge	a5,s1,80006128 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000610a:	f9442503          	lw	a0,-108(s0)
    8000610e:	00000097          	auipc	ra,0x0
    80006112:	ce8080e7          	jalr	-792(ra) # 80005df6 <free_desc>
      for(int j = 0; j < i; j++)
    80006116:	4789                	li	a5,2
    80006118:	0097d863          	bge	a5,s1,80006128 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000611c:	f9842503          	lw	a0,-104(s0)
    80006120:	00000097          	auipc	ra,0x0
    80006124:	cd6080e7          	jalr	-810(ra) # 80005df6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006128:	85e2                	mv	a1,s8
    8000612a:	0001c517          	auipc	a0,0x1c
    8000612e:	f7e50513          	addi	a0,a0,-130 # 800220a8 <disk+0x18>
    80006132:	ffffc097          	auipc	ra,0xffffc
    80006136:	fb0080e7          	jalr	-80(ra) # 800020e2 <sleep>
  for(int i = 0; i < 3; i++){
    8000613a:	f9040713          	addi	a4,s0,-112
    8000613e:	84ce                	mv	s1,s3
    80006140:	bf59                	j	800060d6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006142:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006146:	00479693          	slli	a3,a5,0x4
    8000614a:	0001c797          	auipc	a5,0x1c
    8000614e:	f4678793          	addi	a5,a5,-186 # 80022090 <disk>
    80006152:	97b6                	add	a5,a5,a3
    80006154:	4685                	li	a3,1
    80006156:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006158:	0001c597          	auipc	a1,0x1c
    8000615c:	f3858593          	addi	a1,a1,-200 # 80022090 <disk>
    80006160:	00a60793          	addi	a5,a2,10
    80006164:	0792                	slli	a5,a5,0x4
    80006166:	97ae                	add	a5,a5,a1
    80006168:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000616c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006170:	f6070693          	addi	a3,a4,-160
    80006174:	619c                	ld	a5,0(a1)
    80006176:	97b6                	add	a5,a5,a3
    80006178:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000617a:	6188                	ld	a0,0(a1)
    8000617c:	96aa                	add	a3,a3,a0
    8000617e:	47c1                	li	a5,16
    80006180:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006182:	4785                	li	a5,1
    80006184:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006188:	f9442783          	lw	a5,-108(s0)
    8000618c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006190:	0792                	slli	a5,a5,0x4
    80006192:	953e                	add	a0,a0,a5
    80006194:	05890693          	addi	a3,s2,88
    80006198:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000619a:	6188                	ld	a0,0(a1)
    8000619c:	97aa                	add	a5,a5,a0
    8000619e:	40000693          	li	a3,1024
    800061a2:	c794                	sw	a3,8(a5)
  if(write)
    800061a4:	100d0d63          	beqz	s10,800062be <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061a8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061ac:	00c7d683          	lhu	a3,12(a5)
    800061b0:	0016e693          	ori	a3,a3,1
    800061b4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800061b8:	f9842583          	lw	a1,-104(s0)
    800061bc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061c0:	0001c697          	auipc	a3,0x1c
    800061c4:	ed068693          	addi	a3,a3,-304 # 80022090 <disk>
    800061c8:	00260793          	addi	a5,a2,2
    800061cc:	0792                	slli	a5,a5,0x4
    800061ce:	97b6                	add	a5,a5,a3
    800061d0:	587d                	li	a6,-1
    800061d2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061d6:	0592                	slli	a1,a1,0x4
    800061d8:	952e                	add	a0,a0,a1
    800061da:	f9070713          	addi	a4,a4,-112
    800061de:	9736                	add	a4,a4,a3
    800061e0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800061e2:	6298                	ld	a4,0(a3)
    800061e4:	972e                	add	a4,a4,a1
    800061e6:	4585                	li	a1,1
    800061e8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061ea:	4509                	li	a0,2
    800061ec:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800061f0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061f4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061f8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061fc:	6698                	ld	a4,8(a3)
    800061fe:	00275783          	lhu	a5,2(a4)
    80006202:	8b9d                	andi	a5,a5,7
    80006204:	0786                	slli	a5,a5,0x1
    80006206:	97ba                	add	a5,a5,a4
    80006208:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000620c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006210:	6698                	ld	a4,8(a3)
    80006212:	00275783          	lhu	a5,2(a4)
    80006216:	2785                	addiw	a5,a5,1
    80006218:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000621c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006220:	100017b7          	lui	a5,0x10001
    80006224:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006228:	00492703          	lw	a4,4(s2)
    8000622c:	4785                	li	a5,1
    8000622e:	02f71163          	bne	a4,a5,80006250 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006232:	0001c997          	auipc	s3,0x1c
    80006236:	f8698993          	addi	s3,s3,-122 # 800221b8 <disk+0x128>
  while(b->disk == 1) {
    8000623a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000623c:	85ce                	mv	a1,s3
    8000623e:	854a                	mv	a0,s2
    80006240:	ffffc097          	auipc	ra,0xffffc
    80006244:	ea2080e7          	jalr	-350(ra) # 800020e2 <sleep>
  while(b->disk == 1) {
    80006248:	00492783          	lw	a5,4(s2)
    8000624c:	fe9788e3          	beq	a5,s1,8000623c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006250:	f9042903          	lw	s2,-112(s0)
    80006254:	00290793          	addi	a5,s2,2
    80006258:	00479713          	slli	a4,a5,0x4
    8000625c:	0001c797          	auipc	a5,0x1c
    80006260:	e3478793          	addi	a5,a5,-460 # 80022090 <disk>
    80006264:	97ba                	add	a5,a5,a4
    80006266:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000626a:	0001c997          	auipc	s3,0x1c
    8000626e:	e2698993          	addi	s3,s3,-474 # 80022090 <disk>
    80006272:	00491713          	slli	a4,s2,0x4
    80006276:	0009b783          	ld	a5,0(s3)
    8000627a:	97ba                	add	a5,a5,a4
    8000627c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006280:	854a                	mv	a0,s2
    80006282:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006286:	00000097          	auipc	ra,0x0
    8000628a:	b70080e7          	jalr	-1168(ra) # 80005df6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000628e:	8885                	andi	s1,s1,1
    80006290:	f0ed                	bnez	s1,80006272 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006292:	0001c517          	auipc	a0,0x1c
    80006296:	f2650513          	addi	a0,a0,-218 # 800221b8 <disk+0x128>
    8000629a:	ffffb097          	auipc	ra,0xffffb
    8000629e:	a04080e7          	jalr	-1532(ra) # 80000c9e <release>
}
    800062a2:	70a6                	ld	ra,104(sp)
    800062a4:	7406                	ld	s0,96(sp)
    800062a6:	64e6                	ld	s1,88(sp)
    800062a8:	6946                	ld	s2,80(sp)
    800062aa:	69a6                	ld	s3,72(sp)
    800062ac:	6a06                	ld	s4,64(sp)
    800062ae:	7ae2                	ld	s5,56(sp)
    800062b0:	7b42                	ld	s6,48(sp)
    800062b2:	7ba2                	ld	s7,40(sp)
    800062b4:	7c02                	ld	s8,32(sp)
    800062b6:	6ce2                	ld	s9,24(sp)
    800062b8:	6d42                	ld	s10,16(sp)
    800062ba:	6165                	addi	sp,sp,112
    800062bc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062be:	4689                	li	a3,2
    800062c0:	00d79623          	sh	a3,12(a5)
    800062c4:	b5e5                	j	800061ac <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062c6:	f9042603          	lw	a2,-112(s0)
    800062ca:	00a60713          	addi	a4,a2,10
    800062ce:	0712                	slli	a4,a4,0x4
    800062d0:	0001c517          	auipc	a0,0x1c
    800062d4:	dc850513          	addi	a0,a0,-568 # 80022098 <disk+0x8>
    800062d8:	953a                	add	a0,a0,a4
  if(write)
    800062da:	e60d14e3          	bnez	s10,80006142 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062de:	00a60793          	addi	a5,a2,10
    800062e2:	00479693          	slli	a3,a5,0x4
    800062e6:	0001c797          	auipc	a5,0x1c
    800062ea:	daa78793          	addi	a5,a5,-598 # 80022090 <disk>
    800062ee:	97b6                	add	a5,a5,a3
    800062f0:	0007a423          	sw	zero,8(a5)
    800062f4:	b595                	j	80006158 <virtio_disk_rw+0xf0>

00000000800062f6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062f6:	1101                	addi	sp,sp,-32
    800062f8:	ec06                	sd	ra,24(sp)
    800062fa:	e822                	sd	s0,16(sp)
    800062fc:	e426                	sd	s1,8(sp)
    800062fe:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006300:	0001c497          	auipc	s1,0x1c
    80006304:	d9048493          	addi	s1,s1,-624 # 80022090 <disk>
    80006308:	0001c517          	auipc	a0,0x1c
    8000630c:	eb050513          	addi	a0,a0,-336 # 800221b8 <disk+0x128>
    80006310:	ffffb097          	auipc	ra,0xffffb
    80006314:	8da080e7          	jalr	-1830(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006318:	10001737          	lui	a4,0x10001
    8000631c:	533c                	lw	a5,96(a4)
    8000631e:	8b8d                	andi	a5,a5,3
    80006320:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006322:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006326:	689c                	ld	a5,16(s1)
    80006328:	0204d703          	lhu	a4,32(s1)
    8000632c:	0027d783          	lhu	a5,2(a5)
    80006330:	04f70863          	beq	a4,a5,80006380 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006334:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006338:	6898                	ld	a4,16(s1)
    8000633a:	0204d783          	lhu	a5,32(s1)
    8000633e:	8b9d                	andi	a5,a5,7
    80006340:	078e                	slli	a5,a5,0x3
    80006342:	97ba                	add	a5,a5,a4
    80006344:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006346:	00278713          	addi	a4,a5,2
    8000634a:	0712                	slli	a4,a4,0x4
    8000634c:	9726                	add	a4,a4,s1
    8000634e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006352:	e721                	bnez	a4,8000639a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006354:	0789                	addi	a5,a5,2
    80006356:	0792                	slli	a5,a5,0x4
    80006358:	97a6                	add	a5,a5,s1
    8000635a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000635c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006360:	ffffc097          	auipc	ra,0xffffc
    80006364:	de6080e7          	jalr	-538(ra) # 80002146 <wakeup>

    disk.used_idx += 1;
    80006368:	0204d783          	lhu	a5,32(s1)
    8000636c:	2785                	addiw	a5,a5,1
    8000636e:	17c2                	slli	a5,a5,0x30
    80006370:	93c1                	srli	a5,a5,0x30
    80006372:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006376:	6898                	ld	a4,16(s1)
    80006378:	00275703          	lhu	a4,2(a4)
    8000637c:	faf71ce3          	bne	a4,a5,80006334 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006380:	0001c517          	auipc	a0,0x1c
    80006384:	e3850513          	addi	a0,a0,-456 # 800221b8 <disk+0x128>
    80006388:	ffffb097          	auipc	ra,0xffffb
    8000638c:	916080e7          	jalr	-1770(ra) # 80000c9e <release>
}
    80006390:	60e2                	ld	ra,24(sp)
    80006392:	6442                	ld	s0,16(sp)
    80006394:	64a2                	ld	s1,8(sp)
    80006396:	6105                	addi	sp,sp,32
    80006398:	8082                	ret
      panic("virtio_disk_intr status");
    8000639a:	00002517          	auipc	a0,0x2
    8000639e:	4f650513          	addi	a0,a0,1270 # 80008890 <syscalls+0x3e8>
    800063a2:	ffffa097          	auipc	ra,0xffffa
    800063a6:	1a2080e7          	jalr	418(ra) # 80000544 <panic>
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
