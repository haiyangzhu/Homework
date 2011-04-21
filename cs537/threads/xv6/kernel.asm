
kernel:     file format elf32-i386


Disassembly of section .text:

00100000 <multiboot_header>:
  100000:	02 b0 ad 1b 01 00    	add    0x11bad(%eax),%dh
  100006:	01 00                	add    %eax,(%eax)
  100008:	fd                   	std    
  100009:	4f                   	dec    %edi
  10000a:	51                   	push   %ecx
  10000b:	e4 00                	in     $0x0,%al
  10000d:	00 10                	add    %dl,(%eax)
  10000f:	00 00                	add    %al,(%eax)
  100011:	00 10                	add    %dl,(%eax)
  100013:	00 06                	add    %al,(%esi)
  100015:	78 10                	js     100027 <multiboot_entry+0x7>
  100017:	00 a4 e8 10 00 20 00 	add    %ah,0x200010(%eax,%ebp,8)
  10001e:	10 00                	adc    %al,(%eax)

00100020 <multiboot_entry>:
# Multiboot entry point.  Machine is mostly set up.
# Configure the GDT to match the environment that our usual
# boot loader - bootasm.S - sets up.
.globl multiboot_entry
multiboot_entry:
  lgdt gdtdesc
  100020:	0f 01 15 64 00 10 00 	lgdtl  0x100064
  ljmp $(SEG_KCODE<<3), $mbstart32
  100027:	ea 2e 00 10 00 08 00 	ljmp   $0x8,$0x10002e

0010002e <mbstart32>:

mbstart32:
  # Set up the protected-mode data segment registers
  movw    $(SEG_KDATA<<3), %ax    # Our data segment selector
  10002e:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
  100032:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
  100034:	8e c0                	mov    %eax,%es
  movw    %ax, %ss                # -> SS: Stack Segment
  100036:	8e d0                	mov    %eax,%ss
  movw    $0, %ax                 # Zero segments not ready for use
  100038:	66 b8 00 00          	mov    $0x0,%ax
  movw    %ax, %fs                # -> FS
  10003c:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
  10003e:	8e e8                	mov    %eax,%gs

  # Set up the stack pointer and call into C.
  movl $(stack + STACK), %esp
  100040:	bc e0 88 10 00       	mov    $0x1088e0,%esp
  call main
  100045:	e8 66 28 00 00       	call   1028b0 <main>

0010004a <spin>:
spin:
  jmp spin
  10004a:	eb fe                	jmp    10004a <spin>

0010004c <gdt>:
	...
  100054:	ff                   	(bad)  
  100055:	ff 00                	incl   (%eax)
  100057:	00 00                	add    %al,(%eax)
  100059:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
  100060:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

00100064 <gdtdesc>:
  100064:	17                   	pop    %ss
  100065:	00 4c 00 10          	add    %cl,0x10(%eax,%eax,1)
  100069:	00 90 90 90 90 90    	add    %dl,-0x6f6f6f70(%eax)
  10006f:	90                   	nop

00100070 <brelse>:
}

// Release the buffer b.
void
brelse(struct buf *b)
{
  100070:	55                   	push   %ebp
  100071:	89 e5                	mov    %esp,%ebp
  100073:	53                   	push   %ebx
  100074:	83 ec 14             	sub    $0x14,%esp
  100077:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if((b->flags & B_BUSY) == 0)
  10007a:	f6 03 01             	testb  $0x1,(%ebx)
  10007d:	74 57                	je     1000d6 <brelse+0x66>
    panic("brelse");

  acquire(&bcache.lock);
  10007f:	c7 04 24 e0 88 10 00 	movl   $0x1088e0,(%esp)
  100086:	e8 f5 3b 00 00       	call   103c80 <acquire>

  b->next->prev = b->prev;
  10008b:	8b 43 10             	mov    0x10(%ebx),%eax
  10008e:	8b 53 0c             	mov    0xc(%ebx),%edx
  100091:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
  100094:	8b 43 0c             	mov    0xc(%ebx),%eax
  100097:	8b 53 10             	mov    0x10(%ebx),%edx
  10009a:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
  10009d:	a1 14 9e 10 00       	mov    0x109e14,%eax
  b->prev = &bcache.head;
  1000a2:	c7 43 0c 04 9e 10 00 	movl   $0x109e04,0xc(%ebx)

  acquire(&bcache.lock);

  b->next->prev = b->prev;
  b->prev->next = b->next;
  b->next = bcache.head.next;
  1000a9:	89 43 10             	mov    %eax,0x10(%ebx)
  b->prev = &bcache.head;
  bcache.head.next->prev = b;
  1000ac:	a1 14 9e 10 00       	mov    0x109e14,%eax
  1000b1:	89 58 0c             	mov    %ebx,0xc(%eax)
  bcache.head.next = b;
  1000b4:	89 1d 14 9e 10 00    	mov    %ebx,0x109e14

  b->flags &= ~B_BUSY;
  1000ba:	83 23 fe             	andl   $0xfffffffe,(%ebx)
  wakeup(b);
  1000bd:	89 1c 24             	mov    %ebx,(%esp)
  1000c0:	e8 6b 30 00 00       	call   103130 <wakeup>

  release(&bcache.lock);
  1000c5:	c7 45 08 e0 88 10 00 	movl   $0x1088e0,0x8(%ebp)
}
  1000cc:	83 c4 14             	add    $0x14,%esp
  1000cf:	5b                   	pop    %ebx
  1000d0:	5d                   	pop    %ebp
  bcache.head.next = b;

  b->flags &= ~B_BUSY;
  wakeup(b);

  release(&bcache.lock);
  1000d1:	e9 5a 3b 00 00       	jmp    103c30 <release>
// Release the buffer b.
void
brelse(struct buf *b)
{
  if((b->flags & B_BUSY) == 0)
    panic("brelse");
  1000d6:	c7 04 24 e0 65 10 00 	movl   $0x1065e0,(%esp)
  1000dd:	e8 3e 08 00 00       	call   100920 <panic>
  1000e2:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  1000e9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001000f0 <bwrite>:
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  1000f0:	55                   	push   %ebp
  1000f1:	89 e5                	mov    %esp,%ebp
  1000f3:	83 ec 18             	sub    $0x18,%esp
  1000f6:	8b 45 08             	mov    0x8(%ebp),%eax
  if((b->flags & B_BUSY) == 0)
  1000f9:	8b 10                	mov    (%eax),%edx
  1000fb:	f6 c2 01             	test   $0x1,%dl
  1000fe:	74 0e                	je     10010e <bwrite+0x1e>
    panic("bwrite");
  b->flags |= B_DIRTY;
  100100:	83 ca 04             	or     $0x4,%edx
  100103:	89 10                	mov    %edx,(%eax)
  iderw(b);
  100105:	89 45 08             	mov    %eax,0x8(%ebp)
}
  100108:	c9                   	leave  
bwrite(struct buf *b)
{
  if((b->flags & B_BUSY) == 0)
    panic("bwrite");
  b->flags |= B_DIRTY;
  iderw(b);
  100109:	e9 32 1e 00 00       	jmp    101f40 <iderw>
// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if((b->flags & B_BUSY) == 0)
    panic("bwrite");
  10010e:	c7 04 24 e7 65 10 00 	movl   $0x1065e7,(%esp)
  100115:	e8 06 08 00 00       	call   100920 <panic>
  10011a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00100120 <bread>:
}

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
  100120:	55                   	push   %ebp
  100121:	89 e5                	mov    %esp,%ebp
  100123:	57                   	push   %edi
  100124:	56                   	push   %esi
  100125:	53                   	push   %ebx
  100126:	83 ec 1c             	sub    $0x1c,%esp
  100129:	8b 75 08             	mov    0x8(%ebp),%esi
  10012c:	8b 7d 0c             	mov    0xc(%ebp),%edi
static struct buf*
bget(uint dev, uint sector)
{
  struct buf *b;

  acquire(&bcache.lock);
  10012f:	c7 04 24 e0 88 10 00 	movl   $0x1088e0,(%esp)
  100136:	e8 45 3b 00 00       	call   103c80 <acquire>

 loop:
  // Try for cached block.
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
  10013b:	8b 1d 14 9e 10 00    	mov    0x109e14,%ebx
  100141:	81 fb 04 9e 10 00    	cmp    $0x109e04,%ebx
  100147:	75 12                	jne    10015b <bread+0x3b>
  100149:	eb 35                	jmp    100180 <bread+0x60>
  10014b:	90                   	nop
  10014c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  100150:	8b 5b 10             	mov    0x10(%ebx),%ebx
  100153:	81 fb 04 9e 10 00    	cmp    $0x109e04,%ebx
  100159:	74 25                	je     100180 <bread+0x60>
    if(b->dev == dev && b->sector == sector){
  10015b:	3b 73 04             	cmp    0x4(%ebx),%esi
  10015e:	66 90                	xchg   %ax,%ax
  100160:	75 ee                	jne    100150 <bread+0x30>
  100162:	3b 7b 08             	cmp    0x8(%ebx),%edi
  100165:	75 e9                	jne    100150 <bread+0x30>
      if(!(b->flags & B_BUSY)){
  100167:	8b 03                	mov    (%ebx),%eax
  100169:	a8 01                	test   $0x1,%al
  10016b:	74 64                	je     1001d1 <bread+0xb1>
        b->flags |= B_BUSY;
        release(&bcache.lock);
        return b;
      }
      sleep(b, &bcache.lock);
  10016d:	c7 44 24 04 e0 88 10 	movl   $0x1088e0,0x4(%esp)
  100174:	00 
  100175:	89 1c 24             	mov    %ebx,(%esp)
  100178:	e8 d3 30 00 00       	call   103250 <sleep>
  10017d:	eb bc                	jmp    10013b <bread+0x1b>
  10017f:	90                   	nop
      goto loop;
    }
  }

  // Allocate fresh block.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
  100180:	8b 1d 10 9e 10 00    	mov    0x109e10,%ebx
  100186:	81 fb 04 9e 10 00    	cmp    $0x109e04,%ebx
  10018c:	75 0d                	jne    10019b <bread+0x7b>
  10018e:	eb 54                	jmp    1001e4 <bread+0xc4>
  100190:	8b 5b 0c             	mov    0xc(%ebx),%ebx
  100193:	81 fb 04 9e 10 00    	cmp    $0x109e04,%ebx
  100199:	74 49                	je     1001e4 <bread+0xc4>
    if((b->flags & B_BUSY) == 0){
  10019b:	f6 03 01             	testb  $0x1,(%ebx)
  10019e:	66 90                	xchg   %ax,%ax
  1001a0:	75 ee                	jne    100190 <bread+0x70>
      b->dev = dev;
  1001a2:	89 73 04             	mov    %esi,0x4(%ebx)
      b->sector = sector;
  1001a5:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = B_BUSY;
  1001a8:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
      release(&bcache.lock);
  1001ae:	c7 04 24 e0 88 10 00 	movl   $0x1088e0,(%esp)
  1001b5:	e8 76 3a 00 00       	call   103c30 <release>
bread(uint dev, uint sector)
{
  struct buf *b;

  b = bget(dev, sector);
  if(!(b->flags & B_VALID))
  1001ba:	f6 03 02             	testb  $0x2,(%ebx)
  1001bd:	75 08                	jne    1001c7 <bread+0xa7>
    iderw(b);
  1001bf:	89 1c 24             	mov    %ebx,(%esp)
  1001c2:	e8 79 1d 00 00       	call   101f40 <iderw>
  return b;
}
  1001c7:	83 c4 1c             	add    $0x1c,%esp
  1001ca:	89 d8                	mov    %ebx,%eax
  1001cc:	5b                   	pop    %ebx
  1001cd:	5e                   	pop    %esi
  1001ce:	5f                   	pop    %edi
  1001cf:	5d                   	pop    %ebp
  1001d0:	c3                   	ret    
 loop:
  // Try for cached block.
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    if(b->dev == dev && b->sector == sector){
      if(!(b->flags & B_BUSY)){
        b->flags |= B_BUSY;
  1001d1:	83 c8 01             	or     $0x1,%eax
  1001d4:	89 03                	mov    %eax,(%ebx)
        release(&bcache.lock);
  1001d6:	c7 04 24 e0 88 10 00 	movl   $0x1088e0,(%esp)
  1001dd:	e8 4e 3a 00 00       	call   103c30 <release>
  1001e2:	eb d6                	jmp    1001ba <bread+0x9a>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
  1001e4:	c7 04 24 ee 65 10 00 	movl   $0x1065ee,(%esp)
  1001eb:	e8 30 07 00 00       	call   100920 <panic>

001001f0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
  1001f0:	55                   	push   %ebp
  1001f1:	89 e5                	mov    %esp,%ebp
  1001f3:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
  1001f6:	c7 44 24 04 ff 65 10 	movl   $0x1065ff,0x4(%esp)
  1001fd:	00 
  1001fe:	c7 04 24 e0 88 10 00 	movl   $0x1088e0,(%esp)
  100205:	e8 e6 38 00 00       	call   103af0 <initlock>
  // head.next is most recently used.
  struct buf head;
} bcache;

void
binit(void)
  10020a:	ba 04 9e 10 00       	mov    $0x109e04,%edx
  10020f:	b8 14 89 10 00       	mov    $0x108914,%eax
  struct buf *b;

  initlock(&bcache.lock, "bcache");

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  100214:	c7 05 10 9e 10 00 04 	movl   $0x109e04,0x109e10
  10021b:	9e 10 00 
  bcache.head.next = &bcache.head;
  10021e:	c7 05 14 9e 10 00 04 	movl   $0x109e04,0x109e14
  100225:	9e 10 00 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    b->next = bcache.head.next;
  100228:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
  10022b:	c7 40 0c 04 9e 10 00 	movl   $0x109e04,0xc(%eax)
    b->dev = -1;
  100232:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
  100239:	8b 15 14 9e 10 00    	mov    0x109e14,%edx
  10023f:	89 42 0c             	mov    %eax,0xc(%edx)
  initlock(&bcache.lock, "bcache");

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
  100242:	89 c2                	mov    %eax,%edx
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  100244:	a3 14 9e 10 00       	mov    %eax,0x109e14
  initlock(&bcache.lock, "bcache");

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
  100249:	05 18 02 00 00       	add    $0x218,%eax
  10024e:	3d 04 9e 10 00       	cmp    $0x109e04,%eax
  100253:	75 d3                	jne    100228 <binit+0x38>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
  100255:	c9                   	leave  
  100256:	c3                   	ret    
  100257:	90                   	nop
  100258:	90                   	nop
  100259:	90                   	nop
  10025a:	90                   	nop
  10025b:	90                   	nop
  10025c:	90                   	nop
  10025d:	90                   	nop
  10025e:	90                   	nop
  10025f:	90                   	nop

00100260 <consoleinit>:
  return n;
}

void
consoleinit(void)
{
  100260:	55                   	push   %ebp
  100261:	89 e5                	mov    %esp,%ebp
  100263:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
  100266:	c7 44 24 04 06 66 10 	movl   $0x106606,0x4(%esp)
  10026d:	00 
  10026e:	c7 04 24 40 78 10 00 	movl   $0x107840,(%esp)
  100275:	e8 76 38 00 00       	call   103af0 <initlock>
  initlock(&input.lock, "input");
  10027a:	c7 44 24 04 0e 66 10 	movl   $0x10660e,0x4(%esp)
  100281:	00 
  100282:	c7 04 24 20 a0 10 00 	movl   $0x10a020,(%esp)
  100289:	e8 62 38 00 00       	call   103af0 <initlock>

  devsw[CONSOLE].write = consolewrite;
  devsw[CONSOLE].read = consoleread;
  cons.locking = 1;

  picenable(IRQ_KBD);
  10028e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
consoleinit(void)
{
  initlock(&cons.lock, "console");
  initlock(&input.lock, "input");

  devsw[CONSOLE].write = consolewrite;
  100295:	c7 05 8c aa 10 00 40 	movl   $0x100440,0x10aa8c
  10029c:	04 10 00 
  devsw[CONSOLE].read = consoleread;
  10029f:	c7 05 88 aa 10 00 90 	movl   $0x100690,0x10aa88
  1002a6:	06 10 00 
  cons.locking = 1;
  1002a9:	c7 05 74 78 10 00 01 	movl   $0x1,0x107874
  1002b0:	00 00 00 

  picenable(IRQ_KBD);
  1002b3:	e8 d8 28 00 00       	call   102b90 <picenable>
  ioapicenable(IRQ_KBD, 0);
  1002b8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1002bf:	00 
  1002c0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1002c7:	e8 74 1e 00 00       	call   102140 <ioapicenable>
}
  1002cc:	c9                   	leave  
  1002cd:	c3                   	ret    
  1002ce:	66 90                	xchg   %ax,%ax

001002d0 <consputc>:
  crt[pos] = ' ' | 0x0700;
}

void
consputc(int c)
{
  1002d0:	55                   	push   %ebp
  1002d1:	89 e5                	mov    %esp,%ebp
  1002d3:	57                   	push   %edi
  1002d4:	56                   	push   %esi
  1002d5:	89 c6                	mov    %eax,%esi
  1002d7:	53                   	push   %ebx
  1002d8:	83 ec 1c             	sub    $0x1c,%esp
  if(panicked){
  1002db:	83 3d 20 78 10 00 00 	cmpl   $0x0,0x107820
  1002e2:	74 03                	je     1002e7 <consputc+0x17>
}

static inline void
cli(void)
{
  asm volatile("cli");
  1002e4:	fa                   	cli    
  1002e5:	eb fe                	jmp    1002e5 <consputc+0x15>
    cli();
    for(;;)
      ;
  }

  if(c == BACKSPACE){
  1002e7:	3d 00 01 00 00       	cmp    $0x100,%eax
  1002ec:	0f 84 a0 00 00 00    	je     100392 <consputc+0xc2>
    uartputc('\b'); uartputc(' '); uartputc('\b');
  } else
    uartputc(c);
  1002f2:	89 04 24             	mov    %eax,(%esp)
  1002f5:	e8 f6 4e 00 00       	call   1051f0 <uartputc>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  1002fa:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
  1002ff:	b8 0e 00 00 00       	mov    $0xe,%eax
  100304:	89 ca                	mov    %ecx,%edx
  100306:	ee                   	out    %al,(%dx)
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  100307:	bf d5 03 00 00       	mov    $0x3d5,%edi
  10030c:	89 fa                	mov    %edi,%edx
  10030e:	ec                   	in     (%dx),%al
{
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
  pos = inb(CRTPORT+1) << 8;
  10030f:	0f b6 d8             	movzbl %al,%ebx
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  100312:	89 ca                	mov    %ecx,%edx
  100314:	c1 e3 08             	shl    $0x8,%ebx
  100317:	b8 0f 00 00 00       	mov    $0xf,%eax
  10031c:	ee                   	out    %al,(%dx)
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  10031d:	89 fa                	mov    %edi,%edx
  10031f:	ec                   	in     (%dx),%al
  outb(CRTPORT, 15);
  pos |= inb(CRTPORT+1);
  100320:	0f b6 c0             	movzbl %al,%eax
  100323:	09 c3                	or     %eax,%ebx

  if(c == '\n')
  100325:	83 fe 0a             	cmp    $0xa,%esi
  100328:	0f 84 ee 00 00 00    	je     10041c <consputc+0x14c>
    pos += 80 - pos%80;
  else if(c == BACKSPACE){
  10032e:	81 fe 00 01 00 00    	cmp    $0x100,%esi
  100334:	0f 84 cb 00 00 00    	je     100405 <consputc+0x135>
    if(pos > 0) --pos;
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
  10033a:	66 81 e6 ff 00       	and    $0xff,%si
  10033f:	66 81 ce 00 07       	or     $0x700,%si
  100344:	66 89 b4 1b 00 80 0b 	mov    %si,0xb8000(%ebx,%ebx,1)
  10034b:	00 
  10034c:	83 c3 01             	add    $0x1,%ebx
  
  if((pos/80) >= 24){  // Scroll up.
  10034f:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
  100355:	8d 8c 1b 00 80 0b 00 	lea    0xb8000(%ebx,%ebx,1),%ecx
  10035c:	7f 5d                	jg     1003bb <consputc+0xeb>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  10035e:	be d4 03 00 00       	mov    $0x3d4,%esi
  100363:	b8 0e 00 00 00       	mov    $0xe,%eax
  100368:	89 f2                	mov    %esi,%edx
  10036a:	ee                   	out    %al,(%dx)
  10036b:	bf d5 03 00 00       	mov    $0x3d5,%edi
  100370:	89 d8                	mov    %ebx,%eax
  100372:	c1 f8 08             	sar    $0x8,%eax
  100375:	89 fa                	mov    %edi,%edx
  100377:	ee                   	out    %al,(%dx)
  100378:	b8 0f 00 00 00       	mov    $0xf,%eax
  10037d:	89 f2                	mov    %esi,%edx
  10037f:	ee                   	out    %al,(%dx)
  100380:	89 d8                	mov    %ebx,%eax
  100382:	89 fa                	mov    %edi,%edx
  100384:	ee                   	out    %al,(%dx)
  
  outb(CRTPORT, 14);
  outb(CRTPORT+1, pos>>8);
  outb(CRTPORT, 15);
  outb(CRTPORT+1, pos);
  crt[pos] = ' ' | 0x0700;
  100385:	66 c7 01 20 07       	movw   $0x720,(%ecx)
  if(c == BACKSPACE){
    uartputc('\b'); uartputc(' '); uartputc('\b');
  } else
    uartputc(c);
  cgaputc(c);
}
  10038a:	83 c4 1c             	add    $0x1c,%esp
  10038d:	5b                   	pop    %ebx
  10038e:	5e                   	pop    %esi
  10038f:	5f                   	pop    %edi
  100390:	5d                   	pop    %ebp
  100391:	c3                   	ret    
    for(;;)
      ;
  }

  if(c == BACKSPACE){
    uartputc('\b'); uartputc(' '); uartputc('\b');
  100392:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  100399:	e8 52 4e 00 00       	call   1051f0 <uartputc>
  10039e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1003a5:	e8 46 4e 00 00       	call   1051f0 <uartputc>
  1003aa:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  1003b1:	e8 3a 4e 00 00       	call   1051f0 <uartputc>
  1003b6:	e9 3f ff ff ff       	jmp    1002fa <consputc+0x2a>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
  
  if((pos/80) >= 24){  // Scroll up.
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
    pos -= 80;
  1003bb:	83 eb 50             	sub    $0x50,%ebx
    if(pos > 0) --pos;
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
  
  if((pos/80) >= 24){  // Scroll up.
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
  1003be:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
  1003c5:	00 
    pos -= 80;
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
  1003c6:	8d b4 1b 00 80 0b 00 	lea    0xb8000(%ebx,%ebx,1),%esi
    if(pos > 0) --pos;
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
  
  if((pos/80) >= 24){  // Scroll up.
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
  1003cd:	c7 44 24 04 a0 80 0b 	movl   $0xb80a0,0x4(%esp)
  1003d4:	00 
  1003d5:	c7 04 24 00 80 0b 00 	movl   $0xb8000,(%esp)
  1003dc:	e8 bf 39 00 00       	call   103da0 <memmove>
    pos -= 80;
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
  1003e1:	b8 80 07 00 00       	mov    $0x780,%eax
  1003e6:	29 d8                	sub    %ebx,%eax
  1003e8:	01 c0                	add    %eax,%eax
  1003ea:	89 44 24 08          	mov    %eax,0x8(%esp)
  1003ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1003f5:	00 
  1003f6:	89 34 24             	mov    %esi,(%esp)
  1003f9:	e8 22 39 00 00       	call   103d20 <memset>
  outb(CRTPORT+1, pos);
  crt[pos] = ' ' | 0x0700;
}

void
consputc(int c)
  1003fe:	89 f1                	mov    %esi,%ecx
  100400:	e9 59 ff ff ff       	jmp    10035e <consputc+0x8e>
  pos |= inb(CRTPORT+1);

  if(c == '\n')
    pos += 80 - pos%80;
  else if(c == BACKSPACE){
    if(pos > 0) --pos;
  100405:	85 db                	test   %ebx,%ebx
  100407:	8d 8c 1b 00 80 0b 00 	lea    0xb8000(%ebx,%ebx,1),%ecx
  10040e:	0f 8e 4a ff ff ff    	jle    10035e <consputc+0x8e>
  100414:	83 eb 01             	sub    $0x1,%ebx
  100417:	e9 33 ff ff ff       	jmp    10034f <consputc+0x7f>
  pos = inb(CRTPORT+1) << 8;
  outb(CRTPORT, 15);
  pos |= inb(CRTPORT+1);

  if(c == '\n')
    pos += 80 - pos%80;
  10041c:	89 da                	mov    %ebx,%edx
  10041e:	89 d8                	mov    %ebx,%eax
  100420:	b9 50 00 00 00       	mov    $0x50,%ecx
  100425:	83 c3 50             	add    $0x50,%ebx
  100428:	c1 fa 1f             	sar    $0x1f,%edx
  10042b:	f7 f9                	idiv   %ecx
  10042d:	29 d3                	sub    %edx,%ebx
  10042f:	e9 1b ff ff ff       	jmp    10034f <consputc+0x7f>
  100434:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  10043a:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00100440 <consolewrite>:
  return target - n;
}

int
consolewrite(struct inode *ip, char *buf, int n)
{
  100440:	55                   	push   %ebp
  100441:	89 e5                	mov    %esp,%ebp
  100443:	57                   	push   %edi
  100444:	56                   	push   %esi
  100445:	53                   	push   %ebx
  100446:	83 ec 1c             	sub    $0x1c,%esp
  int i;

  iunlock(ip);
  100449:	8b 45 08             	mov    0x8(%ebp),%eax
  return target - n;
}

int
consolewrite(struct inode *ip, char *buf, int n)
{
  10044c:	8b 75 10             	mov    0x10(%ebp),%esi
  10044f:	8b 7d 0c             	mov    0xc(%ebp),%edi
  int i;

  iunlock(ip);
  100452:	89 04 24             	mov    %eax,(%esp)
  100455:	e8 16 13 00 00       	call   101770 <iunlock>
  acquire(&cons.lock);
  10045a:	c7 04 24 40 78 10 00 	movl   $0x107840,(%esp)
  100461:	e8 1a 38 00 00       	call   103c80 <acquire>
  for(i = 0; i < n; i++)
  100466:	85 f6                	test   %esi,%esi
  100468:	7e 16                	jle    100480 <consolewrite+0x40>
  10046a:	31 db                	xor    %ebx,%ebx
  10046c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    consputc(buf[i] & 0xff);
  100470:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
  100474:	83 c3 01             	add    $0x1,%ebx
    consputc(buf[i] & 0xff);
  100477:	e8 54 fe ff ff       	call   1002d0 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
  10047c:	39 de                	cmp    %ebx,%esi
  10047e:	7f f0                	jg     100470 <consolewrite+0x30>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
  100480:	c7 04 24 40 78 10 00 	movl   $0x107840,(%esp)
  100487:	e8 a4 37 00 00       	call   103c30 <release>
  ilock(ip);
  10048c:	8b 45 08             	mov    0x8(%ebp),%eax
  10048f:	89 04 24             	mov    %eax,(%esp)
  100492:	e8 19 17 00 00       	call   101bb0 <ilock>

  return n;
}
  100497:	83 c4 1c             	add    $0x1c,%esp
  10049a:	89 f0                	mov    %esi,%eax
  10049c:	5b                   	pop    %ebx
  10049d:	5e                   	pop    %esi
  10049e:	5f                   	pop    %edi
  10049f:	5d                   	pop    %ebp
  1004a0:	c3                   	ret    
  1004a1:	eb 0d                	jmp    1004b0 <printint>
  1004a3:	90                   	nop
  1004a4:	90                   	nop
  1004a5:	90                   	nop
  1004a6:	90                   	nop
  1004a7:	90                   	nop
  1004a8:	90                   	nop
  1004a9:	90                   	nop
  1004aa:	90                   	nop
  1004ab:	90                   	nop
  1004ac:	90                   	nop
  1004ad:	90                   	nop
  1004ae:	90                   	nop
  1004af:	90                   	nop

001004b0 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
  1004b0:	55                   	push   %ebp
  1004b1:	89 e5                	mov    %esp,%ebp
  1004b3:	57                   	push   %edi
  1004b4:	56                   	push   %esi
  1004b5:	89 d6                	mov    %edx,%esi
  1004b7:	53                   	push   %ebx
  1004b8:	83 ec 1c             	sub    $0x1c,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
  1004bb:	85 c9                	test   %ecx,%ecx
  1004bd:	74 04                	je     1004c3 <printint+0x13>
  1004bf:	85 c0                	test   %eax,%eax
  1004c1:	78 55                	js     100518 <printint+0x68>
    x = -xx;
  else
    x = xx;
  1004c3:	31 ff                	xor    %edi,%edi
  1004c5:	31 c9                	xor    %ecx,%ecx
  1004c7:	8d 5d d8             	lea    -0x28(%ebp),%ebx
  1004ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

  i = 0;
  do{
    buf[i++] = digits[x % base];
  1004d0:	31 d2                	xor    %edx,%edx
  1004d2:	f7 f6                	div    %esi
  1004d4:	0f b6 92 2e 66 10 00 	movzbl 0x10662e(%edx),%edx
  1004db:	88 14 0b             	mov    %dl,(%ebx,%ecx,1)
  1004de:	83 c1 01             	add    $0x1,%ecx
  }while((x /= base) != 0);
  1004e1:	85 c0                	test   %eax,%eax
  1004e3:	75 eb                	jne    1004d0 <printint+0x20>

  if(sign)
  1004e5:	85 ff                	test   %edi,%edi
  1004e7:	74 08                	je     1004f1 <printint+0x41>
    buf[i++] = '-';
  1004e9:	c6 44 0d d8 2d       	movb   $0x2d,-0x28(%ebp,%ecx,1)
  1004ee:	83 c1 01             	add    $0x1,%ecx

  while(--i >= 0)
  1004f1:	8d 71 ff             	lea    -0x1(%ecx),%esi
  1004f4:	01 f3                	add    %esi,%ebx
  1004f6:	66 90                	xchg   %ax,%ax
    consputc(buf[i]);
  1004f8:	0f be 03             	movsbl (%ebx),%eax
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
  1004fb:	83 ee 01             	sub    $0x1,%esi
  1004fe:	83 eb 01             	sub    $0x1,%ebx
    consputc(buf[i]);
  100501:	e8 ca fd ff ff       	call   1002d0 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
  100506:	83 fe ff             	cmp    $0xffffffff,%esi
  100509:	75 ed                	jne    1004f8 <printint+0x48>
    consputc(buf[i]);
}
  10050b:	83 c4 1c             	add    $0x1c,%esp
  10050e:	5b                   	pop    %ebx
  10050f:	5e                   	pop    %esi
  100510:	5f                   	pop    %edi
  100511:	5d                   	pop    %ebp
  100512:	c3                   	ret    
  100513:	90                   	nop
  100514:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    x = -xx;
  100518:	f7 d8                	neg    %eax
  10051a:	bf 01 00 00 00       	mov    $0x1,%edi
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
  10051f:	eb a4                	jmp    1004c5 <printint+0x15>
  100521:	eb 0d                	jmp    100530 <cprintf>
  100523:	90                   	nop
  100524:	90                   	nop
  100525:	90                   	nop
  100526:	90                   	nop
  100527:	90                   	nop
  100528:	90                   	nop
  100529:	90                   	nop
  10052a:	90                   	nop
  10052b:	90                   	nop
  10052c:	90                   	nop
  10052d:	90                   	nop
  10052e:	90                   	nop
  10052f:	90                   	nop

00100530 <cprintf>:
}

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
  100530:	55                   	push   %ebp
  100531:	89 e5                	mov    %esp,%ebp
  100533:	57                   	push   %edi
  100534:	56                   	push   %esi
  100535:	53                   	push   %ebx
  100536:	83 ec 2c             	sub    $0x2c,%esp
  int i, c, state, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
  100539:	8b 3d 74 78 10 00    	mov    0x107874,%edi
  if(locking)
  10053f:	85 ff                	test   %edi,%edi
  100541:	0f 85 31 01 00 00    	jne    100678 <cprintf+0x148>
    acquire(&cons.lock);

  argp = (uint*)(void*)(&fmt + 1);
  state = 0;
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
  100547:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10054a:	0f b6 01             	movzbl (%ecx),%eax
  10054d:	85 c0                	test   %eax,%eax
  10054f:	0f 84 93 00 00 00    	je     1005e8 <cprintf+0xb8>

  locking = cons.locking;
  if(locking)
    acquire(&cons.lock);

  argp = (uint*)(void*)(&fmt + 1);
  100555:	8d 75 0c             	lea    0xc(%ebp),%esi
  100558:	31 db                	xor    %ebx,%ebx
  10055a:	eb 3f                	jmp    10059b <cprintf+0x6b>
  10055c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
  100560:	83 fa 25             	cmp    $0x25,%edx
  100563:	0f 84 b7 00 00 00    	je     100620 <cprintf+0xf0>
  100569:	83 fa 64             	cmp    $0x64,%edx
  10056c:	0f 84 8e 00 00 00    	je     100600 <cprintf+0xd0>
    case '%':
      consputc('%');
      break;
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
  100572:	b8 25 00 00 00       	mov    $0x25,%eax
  100577:	89 55 e0             	mov    %edx,-0x20(%ebp)
  10057a:	e8 51 fd ff ff       	call   1002d0 <consputc>
      consputc(c);
  10057f:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100582:	89 d0                	mov    %edx,%eax
  100584:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  100588:	e8 43 fd ff ff       	call   1002d0 <consputc>
  10058d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  if(locking)
    acquire(&cons.lock);

  argp = (uint*)(void*)(&fmt + 1);
  state = 0;
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
  100590:	83 c3 01             	add    $0x1,%ebx
  100593:	0f b6 04 19          	movzbl (%ecx,%ebx,1),%eax
  100597:	85 c0                	test   %eax,%eax
  100599:	74 4d                	je     1005e8 <cprintf+0xb8>
    if(c != '%'){
  10059b:	83 f8 25             	cmp    $0x25,%eax
  10059e:	75 e8                	jne    100588 <cprintf+0x58>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
  1005a0:	83 c3 01             	add    $0x1,%ebx
  1005a3:	0f b6 14 19          	movzbl (%ecx,%ebx,1),%edx
    if(c == 0)
  1005a7:	85 d2                	test   %edx,%edx
  1005a9:	74 3d                	je     1005e8 <cprintf+0xb8>
      break;
    switch(c){
  1005ab:	83 fa 70             	cmp    $0x70,%edx
  1005ae:	74 12                	je     1005c2 <cprintf+0x92>
  1005b0:	7e ae                	jle    100560 <cprintf+0x30>
  1005b2:	83 fa 73             	cmp    $0x73,%edx
  1005b5:	8d 76 00             	lea    0x0(%esi),%esi
  1005b8:	74 7e                	je     100638 <cprintf+0x108>
  1005ba:	83 fa 78             	cmp    $0x78,%edx
  1005bd:	8d 76 00             	lea    0x0(%esi),%esi
  1005c0:	75 b0                	jne    100572 <cprintf+0x42>
    case 'd':
      printint(*argp++, 10, 1);
      break;
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
  1005c2:	8b 06                	mov    (%esi),%eax
  1005c4:	31 c9                	xor    %ecx,%ecx
  1005c6:	ba 10 00 00 00       	mov    $0x10,%edx
  if(locking)
    acquire(&cons.lock);

  argp = (uint*)(void*)(&fmt + 1);
  state = 0;
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
  1005cb:	83 c3 01             	add    $0x1,%ebx
    case 'd':
      printint(*argp++, 10, 1);
      break;
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
  1005ce:	83 c6 04             	add    $0x4,%esi
  1005d1:	e8 da fe ff ff       	call   1004b0 <printint>
  1005d6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  if(locking)
    acquire(&cons.lock);

  argp = (uint*)(void*)(&fmt + 1);
  state = 0;
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
  1005d9:	0f b6 04 19          	movzbl (%ecx,%ebx,1),%eax
  1005dd:	85 c0                	test   %eax,%eax
  1005df:	75 ba                	jne    10059b <cprintf+0x6b>
  1005e1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
      consputc(c);
      break;
    }
  }

  if(locking)
  1005e8:	85 ff                	test   %edi,%edi
  1005ea:	74 0c                	je     1005f8 <cprintf+0xc8>
    release(&cons.lock);
  1005ec:	c7 04 24 40 78 10 00 	movl   $0x107840,(%esp)
  1005f3:	e8 38 36 00 00       	call   103c30 <release>
}
  1005f8:	83 c4 2c             	add    $0x2c,%esp
  1005fb:	5b                   	pop    %ebx
  1005fc:	5e                   	pop    %esi
  1005fd:	5f                   	pop    %edi
  1005fe:	5d                   	pop    %ebp
  1005ff:	c3                   	ret    
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    case 'd':
      printint(*argp++, 10, 1);
  100600:	8b 06                	mov    (%esi),%eax
  100602:	b9 01 00 00 00       	mov    $0x1,%ecx
  100607:	ba 0a 00 00 00       	mov    $0xa,%edx
  10060c:	83 c6 04             	add    $0x4,%esi
  10060f:	e8 9c fe ff ff       	call   1004b0 <printint>
  100614:	8b 4d 08             	mov    0x8(%ebp),%ecx
      break;
  100617:	e9 74 ff ff ff       	jmp    100590 <cprintf+0x60>
  10061c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
      break;
    case '%':
      consputc('%');
  100620:	b8 25 00 00 00       	mov    $0x25,%eax
  100625:	e8 a6 fc ff ff       	call   1002d0 <consputc>
  10062a:	8b 4d 08             	mov    0x8(%ebp),%ecx
      break;
  10062d:	e9 5e ff ff ff       	jmp    100590 <cprintf+0x60>
  100632:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
  100638:	8b 16                	mov    (%esi),%edx
  10063a:	b8 14 66 10 00       	mov    $0x106614,%eax
  10063f:	83 c6 04             	add    $0x4,%esi
  100642:	85 d2                	test   %edx,%edx
  100644:	0f 44 d0             	cmove  %eax,%edx
        s = "(null)";
      for(; *s; s++)
  100647:	0f b6 02             	movzbl (%edx),%eax
  10064a:	84 c0                	test   %al,%al
  10064c:	0f 84 3e ff ff ff    	je     100590 <cprintf+0x60>
  100652:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  100655:	89 d3                	mov    %edx,%ebx
  100657:	90                   	nop
        consputc(*s);
  100658:	0f be c0             	movsbl %al,%eax
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
  10065b:	83 c3 01             	add    $0x1,%ebx
        consputc(*s);
  10065e:	e8 6d fc ff ff       	call   1002d0 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
  100663:	0f b6 03             	movzbl (%ebx),%eax
  100666:	84 c0                	test   %al,%al
  100668:	75 ee                	jne    100658 <cprintf+0x128>
  10066a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  10066d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  100670:	e9 1b ff ff ff       	jmp    100590 <cprintf+0x60>
  100675:	8d 76 00             	lea    0x0(%esi),%esi
  uint *argp;
  char *s;

  locking = cons.locking;
  if(locking)
    acquire(&cons.lock);
  100678:	c7 04 24 40 78 10 00 	movl   $0x107840,(%esp)
  10067f:	e8 fc 35 00 00       	call   103c80 <acquire>
  100684:	e9 be fe ff ff       	jmp    100547 <cprintf+0x17>
  100689:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00100690 <consoleread>:
  release(&input.lock);
}

int
consoleread(struct inode *ip, char *dst, int n)
{
  100690:	55                   	push   %ebp
  100691:	89 e5                	mov    %esp,%ebp
  100693:	57                   	push   %edi
  100694:	56                   	push   %esi
  100695:	53                   	push   %ebx
  100696:	83 ec 3c             	sub    $0x3c,%esp
  100699:	8b 5d 10             	mov    0x10(%ebp),%ebx
  10069c:	8b 7d 08             	mov    0x8(%ebp),%edi
  10069f:	8b 75 0c             	mov    0xc(%ebp),%esi
  uint target;
  int c;

  iunlock(ip);
  1006a2:	89 3c 24             	mov    %edi,(%esp)
  1006a5:	e8 c6 10 00 00       	call   101770 <iunlock>
  target = n;
  1006aa:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&input.lock);
  1006ad:	c7 04 24 20 a0 10 00 	movl   $0x10a020,(%esp)
  1006b4:	e8 c7 35 00 00       	call   103c80 <acquire>
  while(n > 0){
  1006b9:	85 db                	test   %ebx,%ebx
  1006bb:	7f 2c                	jg     1006e9 <consoleread+0x59>
  1006bd:	e9 c0 00 00 00       	jmp    100782 <consoleread+0xf2>
  1006c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    while(input.r == input.w){
      if(proc->killed){
  1006c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1006ce:	8b 40 24             	mov    0x24(%eax),%eax
  1006d1:	85 c0                	test   %eax,%eax
  1006d3:	75 5b                	jne    100730 <consoleread+0xa0>
        release(&input.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
  1006d5:	c7 44 24 04 20 a0 10 	movl   $0x10a020,0x4(%esp)
  1006dc:	00 
  1006dd:	c7 04 24 d4 a0 10 00 	movl   $0x10a0d4,(%esp)
  1006e4:	e8 67 2b 00 00       	call   103250 <sleep>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
  1006e9:	a1 d4 a0 10 00       	mov    0x10a0d4,%eax
  1006ee:	3b 05 d8 a0 10 00    	cmp    0x10a0d8,%eax
  1006f4:	74 d2                	je     1006c8 <consoleread+0x38>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
  1006f6:	89 c2                	mov    %eax,%edx
  1006f8:	83 e2 7f             	and    $0x7f,%edx
  1006fb:	0f b6 8a 54 a0 10 00 	movzbl 0x10a054(%edx),%ecx
  100702:	0f be d1             	movsbl %cl,%edx
  100705:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  100708:	8d 50 01             	lea    0x1(%eax),%edx
    if(c == C('D')){  // EOF
  10070b:	83 7d d4 04          	cmpl   $0x4,-0x2c(%ebp)
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
  10070f:	89 15 d4 a0 10 00    	mov    %edx,0x10a0d4
    if(c == C('D')){  // EOF
  100715:	74 3a                	je     100751 <consoleread+0xc1>
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
    }
    *dst++ = c;
  100717:	88 0e                	mov    %cl,(%esi)
    --n;
  100719:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
  10071c:	83 7d d4 0a          	cmpl   $0xa,-0x2c(%ebp)
  100720:	74 39                	je     10075b <consoleread+0xcb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
  100722:	85 db                	test   %ebx,%ebx
  100724:	7e 35                	jle    10075b <consoleread+0xcb>
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
    }
    *dst++ = c;
  100726:	83 c6 01             	add    $0x1,%esi
  100729:	eb be                	jmp    1006e9 <consoleread+0x59>
  10072b:	90                   	nop
  10072c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
      if(proc->killed){
        release(&input.lock);
  100730:	c7 04 24 20 a0 10 00 	movl   $0x10a020,(%esp)
  100737:	e8 f4 34 00 00       	call   103c30 <release>
        ilock(ip);
  10073c:	89 3c 24             	mov    %edi,(%esp)
  10073f:	e8 6c 14 00 00       	call   101bb0 <ilock>
  }
  release(&input.lock);
  ilock(ip);

  return target - n;
}
  100744:	83 c4 3c             	add    $0x3c,%esp
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
      if(proc->killed){
        release(&input.lock);
        ilock(ip);
  100747:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&input.lock);
  ilock(ip);

  return target - n;
}
  10074c:	5b                   	pop    %ebx
  10074d:	5e                   	pop    %esi
  10074e:	5f                   	pop    %edi
  10074f:	5d                   	pop    %ebp
  100750:	c3                   	ret    
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
    if(c == C('D')){  // EOF
      if(n < target){
  100751:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
  100754:	76 05                	jbe    10075b <consoleread+0xcb>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
  100756:	a3 d4 a0 10 00       	mov    %eax,0x10a0d4
  10075b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10075e:	29 d8                	sub    %ebx,%eax
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&input.lock);
  100760:	c7 04 24 20 a0 10 00 	movl   $0x10a020,(%esp)
  100767:	89 45 e0             	mov    %eax,-0x20(%ebp)
  10076a:	e8 c1 34 00 00       	call   103c30 <release>
  ilock(ip);
  10076f:	89 3c 24             	mov    %edi,(%esp)
  100772:	e8 39 14 00 00       	call   101bb0 <ilock>
  100777:	8b 45 e0             	mov    -0x20(%ebp),%eax

  return target - n;
}
  10077a:	83 c4 3c             	add    $0x3c,%esp
  10077d:	5b                   	pop    %ebx
  10077e:	5e                   	pop    %esi
  10077f:	5f                   	pop    %edi
  100780:	5d                   	pop    %ebp
  100781:	c3                   	ret    
  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
      if(proc->killed){
  100782:	31 c0                	xor    %eax,%eax
  100784:	eb da                	jmp    100760 <consoleread+0xd0>
  100786:	8d 76 00             	lea    0x0(%esi),%esi
  100789:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100790 <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
  100790:	55                   	push   %ebp
  100791:	89 e5                	mov    %esp,%ebp
  100793:	57                   	push   %edi
      }
      break;
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
        c = (c == '\r') ? '\n' : c;
        input.buf[input.e++ % INPUT_BUF] = c;
  100794:	bf 50 a0 10 00       	mov    $0x10a050,%edi

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
  100799:	56                   	push   %esi
  10079a:	53                   	push   %ebx
  10079b:	83 ec 1c             	sub    $0x1c,%esp
  10079e:	8b 75 08             	mov    0x8(%ebp),%esi
  int c;

  acquire(&input.lock);
  1007a1:	c7 04 24 20 a0 10 00 	movl   $0x10a020,(%esp)
  1007a8:	e8 d3 34 00 00       	call   103c80 <acquire>
  1007ad:	8d 76 00             	lea    0x0(%esi),%esi
  while((c = getc()) >= 0){
  1007b0:	ff d6                	call   *%esi
  1007b2:	85 c0                	test   %eax,%eax
  1007b4:	89 c3                	mov    %eax,%ebx
  1007b6:	0f 88 9c 00 00 00    	js     100858 <consoleintr+0xc8>
    switch(c){
  1007bc:	83 fb 10             	cmp    $0x10,%ebx
  1007bf:	90                   	nop
  1007c0:	0f 84 1a 01 00 00    	je     1008e0 <consoleintr+0x150>
  1007c6:	0f 8f a4 00 00 00    	jg     100870 <consoleintr+0xe0>
  1007cc:	83 fb 08             	cmp    $0x8,%ebx
  1007cf:	90                   	nop
  1007d0:	0f 84 a8 00 00 00    	je     10087e <consoleintr+0xee>
        input.e--;
        consputc(BACKSPACE);
      }
      break;
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
  1007d6:	85 db                	test   %ebx,%ebx
  1007d8:	74 d6                	je     1007b0 <consoleintr+0x20>
  1007da:	a1 dc a0 10 00       	mov    0x10a0dc,%eax
  1007df:	89 c2                	mov    %eax,%edx
  1007e1:	2b 15 d4 a0 10 00    	sub    0x10a0d4,%edx
  1007e7:	83 fa 7f             	cmp    $0x7f,%edx
  1007ea:	77 c4                	ja     1007b0 <consoleintr+0x20>
        c = (c == '\r') ? '\n' : c;
  1007ec:	83 fb 0d             	cmp    $0xd,%ebx
  1007ef:	0f 84 f8 00 00 00    	je     1008ed <consoleintr+0x15d>
        input.buf[input.e++ % INPUT_BUF] = c;
  1007f5:	89 c2                	mov    %eax,%edx
  1007f7:	83 c0 01             	add    $0x1,%eax
  1007fa:	83 e2 7f             	and    $0x7f,%edx
  1007fd:	88 5c 3a 04          	mov    %bl,0x4(%edx,%edi,1)
  100801:	a3 dc a0 10 00       	mov    %eax,0x10a0dc
        consputc(c);
  100806:	89 d8                	mov    %ebx,%eax
  100808:	e8 c3 fa ff ff       	call   1002d0 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
  10080d:	83 fb 04             	cmp    $0x4,%ebx
  100810:	0f 84 f3 00 00 00    	je     100909 <consoleintr+0x179>
  100816:	83 fb 0a             	cmp    $0xa,%ebx
  100819:	0f 84 ea 00 00 00    	je     100909 <consoleintr+0x179>
  10081f:	8b 15 d4 a0 10 00    	mov    0x10a0d4,%edx
  100825:	a1 dc a0 10 00       	mov    0x10a0dc,%eax
  10082a:	83 ea 80             	sub    $0xffffff80,%edx
  10082d:	39 d0                	cmp    %edx,%eax
  10082f:	0f 85 7b ff ff ff    	jne    1007b0 <consoleintr+0x20>
          input.w = input.e;
  100835:	a3 d8 a0 10 00       	mov    %eax,0x10a0d8
          wakeup(&input.r);
  10083a:	c7 04 24 d4 a0 10 00 	movl   $0x10a0d4,(%esp)
  100841:	e8 ea 28 00 00       	call   103130 <wakeup>
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
  100846:	ff d6                	call   *%esi
  100848:	85 c0                	test   %eax,%eax
  10084a:	89 c3                	mov    %eax,%ebx
  10084c:	0f 89 6a ff ff ff    	jns    1007bc <consoleintr+0x2c>
  100852:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
        }
      }
      break;
    }
  }
  release(&input.lock);
  100858:	c7 45 08 20 a0 10 00 	movl   $0x10a020,0x8(%ebp)
}
  10085f:	83 c4 1c             	add    $0x1c,%esp
  100862:	5b                   	pop    %ebx
  100863:	5e                   	pop    %esi
  100864:	5f                   	pop    %edi
  100865:	5d                   	pop    %ebp
        }
      }
      break;
    }
  }
  release(&input.lock);
  100866:	e9 c5 33 00 00       	jmp    103c30 <release>
  10086b:	90                   	nop
  10086c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
    switch(c){
  100870:	83 fb 15             	cmp    $0x15,%ebx
  100873:	74 57                	je     1008cc <consoleintr+0x13c>
  100875:	83 fb 7f             	cmp    $0x7f,%ebx
  100878:	0f 85 58 ff ff ff    	jne    1007d6 <consoleintr+0x46>
        input.e--;
        consputc(BACKSPACE);
      }
      break;
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
  10087e:	a1 dc a0 10 00       	mov    0x10a0dc,%eax
  100883:	3b 05 d8 a0 10 00    	cmp    0x10a0d8,%eax
  100889:	0f 84 21 ff ff ff    	je     1007b0 <consoleintr+0x20>
        input.e--;
  10088f:	83 e8 01             	sub    $0x1,%eax
  100892:	a3 dc a0 10 00       	mov    %eax,0x10a0dc
        consputc(BACKSPACE);
  100897:	b8 00 01 00 00       	mov    $0x100,%eax
  10089c:	e8 2f fa ff ff       	call   1002d0 <consputc>
  1008a1:	e9 0a ff ff ff       	jmp    1007b0 <consoleintr+0x20>
  1008a6:	66 90                	xchg   %ax,%ax
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
  1008a8:	83 e8 01             	sub    $0x1,%eax
  1008ab:	89 c2                	mov    %eax,%edx
  1008ad:	83 e2 7f             	and    $0x7f,%edx
  1008b0:	80 ba 54 a0 10 00 0a 	cmpb   $0xa,0x10a054(%edx)
  1008b7:	0f 84 f3 fe ff ff    	je     1007b0 <consoleintr+0x20>
        input.e--;
  1008bd:	a3 dc a0 10 00       	mov    %eax,0x10a0dc
        consputc(BACKSPACE);
  1008c2:	b8 00 01 00 00       	mov    $0x100,%eax
  1008c7:	e8 04 fa ff ff       	call   1002d0 <consputc>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
  1008cc:	a1 dc a0 10 00       	mov    0x10a0dc,%eax
  1008d1:	3b 05 d8 a0 10 00    	cmp    0x10a0d8,%eax
  1008d7:	75 cf                	jne    1008a8 <consoleintr+0x118>
  1008d9:	e9 d2 fe ff ff       	jmp    1007b0 <consoleintr+0x20>
  1008de:	66 90                	xchg   %ax,%ax

  acquire(&input.lock);
  while((c = getc()) >= 0){
    switch(c){
    case C('P'):  // Process listing.
      procdump();
  1008e0:	e8 eb 26 00 00       	call   102fd0 <procdump>
  1008e5:	8d 76 00             	lea    0x0(%esi),%esi
      break;
  1008e8:	e9 c3 fe ff ff       	jmp    1007b0 <consoleintr+0x20>
      }
      break;
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
        c = (c == '\r') ? '\n' : c;
        input.buf[input.e++ % INPUT_BUF] = c;
  1008ed:	89 c2                	mov    %eax,%edx
  1008ef:	83 c0 01             	add    $0x1,%eax
  1008f2:	83 e2 7f             	and    $0x7f,%edx
  1008f5:	c6 44 3a 04 0a       	movb   $0xa,0x4(%edx,%edi,1)
  1008fa:	a3 dc a0 10 00       	mov    %eax,0x10a0dc
        consputc(c);
  1008ff:	b8 0a 00 00 00       	mov    $0xa,%eax
  100904:	e8 c7 f9 ff ff       	call   1002d0 <consputc>
  100909:	a1 dc a0 10 00       	mov    0x10a0dc,%eax
  10090e:	e9 22 ff ff ff       	jmp    100835 <consoleintr+0xa5>
  100913:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  100919:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100920 <panic>:
    release(&cons.lock);
}

void
panic(char *s)
{
  100920:	55                   	push   %ebp
  100921:	89 e5                	mov    %esp,%ebp
  100923:	56                   	push   %esi
  100924:	53                   	push   %ebx
  100925:	83 ec 40             	sub    $0x40,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
  100928:	fa                   	cli    
  int i;
  uint pcs[10];
  
  cli();
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  100929:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  10092f:	8d 75 d0             	lea    -0x30(%ebp),%esi
  100932:	31 db                	xor    %ebx,%ebx
{
  int i;
  uint pcs[10];
  
  cli();
  cons.locking = 0;
  100934:	c7 05 74 78 10 00 00 	movl   $0x0,0x107874
  10093b:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
  10093e:	0f b6 00             	movzbl (%eax),%eax
  100941:	c7 04 24 1b 66 10 00 	movl   $0x10661b,(%esp)
  100948:	89 44 24 04          	mov    %eax,0x4(%esp)
  10094c:	e8 df fb ff ff       	call   100530 <cprintf>
  cprintf(s);
  100951:	8b 45 08             	mov    0x8(%ebp),%eax
  100954:	89 04 24             	mov    %eax,(%esp)
  100957:	e8 d4 fb ff ff       	call   100530 <cprintf>
  cprintf("\n");
  10095c:	c7 04 24 36 6a 10 00 	movl   $0x106a36,(%esp)
  100963:	e8 c8 fb ff ff       	call   100530 <cprintf>
  getcallerpcs(&s, pcs);
  100968:	8d 45 08             	lea    0x8(%ebp),%eax
  10096b:	89 74 24 04          	mov    %esi,0x4(%esp)
  10096f:	89 04 24             	mov    %eax,(%esp)
  100972:	e8 99 31 00 00       	call   103b10 <getcallerpcs>
  100977:	90                   	nop
  for(i=0; i<10; i++)
    cprintf(" %p", pcs[i]);
  100978:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
  10097b:	83 c3 01             	add    $0x1,%ebx
    cprintf(" %p", pcs[i]);
  10097e:	c7 04 24 2a 66 10 00 	movl   $0x10662a,(%esp)
  100985:	89 44 24 04          	mov    %eax,0x4(%esp)
  100989:	e8 a2 fb ff ff       	call   100530 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
  10098e:	83 fb 0a             	cmp    $0xa,%ebx
  100991:	75 e5                	jne    100978 <panic+0x58>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
  100993:	c7 05 20 78 10 00 01 	movl   $0x1,0x107820
  10099a:	00 00 00 
  10099d:	eb fe                	jmp    10099d <panic+0x7d>
  10099f:	90                   	nop

001009a0 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
  1009a0:	55                   	push   %ebp
  1009a1:	89 e5                	mov    %esp,%ebp
  1009a3:	57                   	push   %edi
  1009a4:	56                   	push   %esi
  1009a5:	53                   	push   %ebx
  1009a6:	81 ec 2c 01 00 00    	sub    $0x12c,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
  1009ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1009af:	89 04 24             	mov    %eax,(%esp)
  1009b2:	e8 99 14 00 00       	call   101e50 <namei>
  1009b7:	85 c0                	test   %eax,%eax
  1009b9:	89 c7                	mov    %eax,%edi
  1009bb:	0f 84 25 01 00 00    	je     100ae6 <exec+0x146>
    return -1;
  ilock(ip);
  1009c1:	89 04 24             	mov    %eax,(%esp)
  1009c4:	e8 e7 11 00 00       	call   101bb0 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
  1009c9:	8d 45 94             	lea    -0x6c(%ebp),%eax
  1009cc:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
  1009d3:	00 
  1009d4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1009db:	00 
  1009dc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009e0:	89 3c 24             	mov    %edi,(%esp)
  1009e3:	e8 78 09 00 00       	call   101360 <readi>
  1009e8:	83 f8 33             	cmp    $0x33,%eax
  1009eb:	0f 86 cf 01 00 00    	jbe    100bc0 <exec+0x220>
    goto bad;
  if(elf.magic != ELF_MAGIC)
  1009f1:	81 7d 94 7f 45 4c 46 	cmpl   $0x464c457f,-0x6c(%ebp)
  1009f8:	0f 85 c2 01 00 00    	jne    100bc0 <exec+0x220>
  1009fe:	66 90                	xchg   %ax,%ax
    goto bad;

  if((pgdir = setupkvm()) == 0)
  100a00:	e8 6b 55 00 00       	call   105f70 <setupkvm>
  100a05:	85 c0                	test   %eax,%eax
  100a07:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
  100a0d:	0f 84 ad 01 00 00    	je     100bc0 <exec+0x220>
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
  100a13:	66 83 7d c0 00       	cmpw   $0x0,-0x40(%ebp)
  100a18:	8b 75 b0             	mov    -0x50(%ebp),%esi
  100a1b:	0f 84 bb 02 00 00    	je     100cdc <exec+0x33c>
  100a21:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  100a28:	00 00 00 
  100a2b:	31 db                	xor    %ebx,%ebx
  100a2d:	eb 13                	jmp    100a42 <exec+0xa2>
  100a2f:	90                   	nop
  100a30:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
  100a34:	83 c3 01             	add    $0x1,%ebx
  100a37:	39 d8                	cmp    %ebx,%eax
  100a39:	0f 8e b9 00 00 00    	jle    100af8 <exec+0x158>
  100a3f:	83 c6 20             	add    $0x20,%esi
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
  100a42:	8d 55 c8             	lea    -0x38(%ebp),%edx
  100a45:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
  100a4c:	00 
  100a4d:	89 74 24 08          	mov    %esi,0x8(%esp)
  100a51:	89 54 24 04          	mov    %edx,0x4(%esp)
  100a55:	89 3c 24             	mov    %edi,(%esp)
  100a58:	e8 03 09 00 00       	call   101360 <readi>
  100a5d:	83 f8 20             	cmp    $0x20,%eax
  100a60:	75 6e                	jne    100ad0 <exec+0x130>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
  100a62:	83 7d c8 01          	cmpl   $0x1,-0x38(%ebp)
  100a66:	75 c8                	jne    100a30 <exec+0x90>
      continue;
    if(ph.memsz < ph.filesz)
  100a68:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100a6b:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  100a6e:	66 90                	xchg   %ax,%ax
  100a70:	72 5e                	jb     100ad0 <exec+0x130>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.va + ph.memsz)) == 0)
  100a72:	03 45 d0             	add    -0x30(%ebp),%eax
  100a75:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
  100a7b:	89 44 24 08          	mov    %eax,0x8(%esp)
  100a7f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  100a85:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  100a89:	89 04 24             	mov    %eax,(%esp)
  100a8c:	e8 df 57 00 00       	call   106270 <allocuvm>
  100a91:	85 c0                	test   %eax,%eax
  100a93:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)
  100a99:	74 35                	je     100ad0 <exec+0x130>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.va, ip, ph.offset, ph.filesz) < 0)
  100a9b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  100a9e:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
  100aa4:	89 7c 24 08          	mov    %edi,0x8(%esp)
  100aa8:	89 44 24 10          	mov    %eax,0x10(%esp)
  100aac:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100aaf:	89 14 24             	mov    %edx,(%esp)
  100ab2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  100ab6:	8b 45 d0             	mov    -0x30(%ebp),%eax
  100ab9:	89 44 24 04          	mov    %eax,0x4(%esp)
  100abd:	e8 7e 58 00 00       	call   106340 <loaduvm>
  100ac2:	85 c0                	test   %eax,%eax
  100ac4:	0f 89 66 ff ff ff    	jns    100a30 <exec+0x90>
  100aca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  100ad0:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  100ad6:	89 04 24             	mov    %eax,(%esp)
  100ad9:	e8 52 56 00 00       	call   106130 <freevm>
  if(ip)
  100ade:	85 ff                	test   %edi,%edi
  100ae0:	0f 85 da 00 00 00    	jne    100bc0 <exec+0x220>
    iunlockput(ip);
  100ae6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  return -1;
}
  100aeb:	81 c4 2c 01 00 00    	add    $0x12c,%esp
  100af1:	5b                   	pop    %ebx
  100af2:	5e                   	pop    %esi
  100af3:	5f                   	pop    %edi
  100af4:	5d                   	pop    %ebp
  100af5:	c3                   	ret    
  100af6:	66 90                	xchg   %ax,%ax
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
  100af8:	8b 9d f4 fe ff ff    	mov    -0x10c(%ebp),%ebx
  100afe:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
  100b04:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  100b0a:	8d b3 00 10 00 00    	lea    0x1000(%ebx),%esi
    if((sz = allocuvm(pgdir, sz, ph.va + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.va, ip, ph.offset, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
  100b10:	89 3c 24             	mov    %edi,(%esp)
  100b13:	e8 a8 0f 00 00       	call   101ac0 <iunlockput>
  ip = 0;

  // Allocate a one-page stack at the next page boundary
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + PGSIZE)) == 0)
  100b18:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
  100b1e:	89 74 24 08          	mov    %esi,0x8(%esp)
  100b22:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  100b26:	89 0c 24             	mov    %ecx,(%esp)
  100b29:	e8 42 57 00 00       	call   106270 <allocuvm>
  100b2e:	85 c0                	test   %eax,%eax
  100b30:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)
  100b36:	74 7f                	je     100bb7 <exec+0x217>
    goto bad;

  // Push argument strings, prepare rest of stack in ustack.
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
  100b38:	8b 55 0c             	mov    0xc(%ebp),%edx
  100b3b:	8b 02                	mov    (%edx),%eax
  100b3d:	85 c0                	test   %eax,%eax
  100b3f:	0f 84 78 01 00 00    	je     100cbd <exec+0x31d>
  100b45:	8b 7d 0c             	mov    0xc(%ebp),%edi
  100b48:	31 f6                	xor    %esi,%esi
  100b4a:	8b 9d f4 fe ff ff    	mov    -0x10c(%ebp),%ebx
  100b50:	eb 28                	jmp    100b7a <exec+0x1da>
  100b52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
      goto bad;
    sp -= strlen(argv[argc]) + 1;
    sp &= ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  100b58:	89 9c b5 10 ff ff ff 	mov    %ebx,-0xf0(%ebp,%esi,4)
#include "defs.h"
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
  100b5f:	8b 45 0c             	mov    0xc(%ebp),%eax
  if((sz = allocuvm(pgdir, sz, sz + PGSIZE)) == 0)
    goto bad;

  // Push argument strings, prepare rest of stack in ustack.
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
  100b62:	83 c6 01             	add    $0x1,%esi
      goto bad;
    sp -= strlen(argv[argc]) + 1;
    sp &= ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  100b65:	8d 95 04 ff ff ff    	lea    -0xfc(%ebp),%edx
#include "defs.h"
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
  100b6b:	8d 3c b0             	lea    (%eax,%esi,4),%edi
  if((sz = allocuvm(pgdir, sz, sz + PGSIZE)) == 0)
    goto bad;

  // Push argument strings, prepare rest of stack in ustack.
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
  100b6e:	8b 04 b0             	mov    (%eax,%esi,4),%eax
  100b71:	85 c0                	test   %eax,%eax
  100b73:	74 5d                	je     100bd2 <exec+0x232>
    if(argc >= MAXARG)
  100b75:	83 fe 20             	cmp    $0x20,%esi
  100b78:	74 3d                	je     100bb7 <exec+0x217>
      goto bad;
    sp -= strlen(argv[argc]) + 1;
  100b7a:	89 04 24             	mov    %eax,(%esp)
  100b7d:	e8 7e 33 00 00       	call   103f00 <strlen>
  100b82:	f7 d0                	not    %eax
  100b84:	8d 1c 18             	lea    (%eax,%ebx,1),%ebx
    sp &= ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
  100b87:	8b 07                	mov    (%edi),%eax
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
    sp -= strlen(argv[argc]) + 1;
    sp &= ~3;
  100b89:	83 e3 fc             	and    $0xfffffffc,%ebx
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
  100b8c:	89 04 24             	mov    %eax,(%esp)
  100b8f:	e8 6c 33 00 00       	call   103f00 <strlen>
  100b94:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
  100b9a:	83 c0 01             	add    $0x1,%eax
  100b9d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  100ba1:	8b 07                	mov    (%edi),%eax
  100ba3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  100ba7:	89 0c 24             	mov    %ecx,(%esp)
  100baa:	89 44 24 08          	mov    %eax,0x8(%esp)
  100bae:	e8 9d 52 00 00       	call   105e50 <copyout>
  100bb3:	85 c0                	test   %eax,%eax
  100bb5:	79 a1                	jns    100b58 <exec+0x1b8>

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip)
    iunlockput(ip);
  100bb7:	31 ff                	xor    %edi,%edi
  100bb9:	e9 12 ff ff ff       	jmp    100ad0 <exec+0x130>
  100bbe:	66 90                	xchg   %ax,%ax
  100bc0:	89 3c 24             	mov    %edi,(%esp)
  100bc3:	e8 f8 0e 00 00       	call   101ac0 <iunlockput>
  100bc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  100bcd:	e9 19 ff ff ff       	jmp    100aeb <exec+0x14b>
  if((sz = allocuvm(pgdir, sz, sz + PGSIZE)) == 0)
    goto bad;

  // Push argument strings, prepare rest of stack in ustack.
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
  100bd2:	8d 4e 03             	lea    0x3(%esi),%ecx
  100bd5:	8d 3c b5 04 00 00 00 	lea    0x4(,%esi,4),%edi
  100bdc:	8d 04 b5 10 00 00 00 	lea    0x10(,%esi,4),%eax
    sp &= ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
  100be3:	c7 84 8d 04 ff ff ff 	movl   $0x0,-0xfc(%ebp,%ecx,4)
  100bea:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer
  100bee:	89 d9                	mov    %ebx,%ecx

  sp -= (3+argc+1) * 4;
  100bf0:	29 c3                	sub    %eax,%ebx
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
  100bf2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  100bf6:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  }
  ustack[3+argc] = 0;

  ustack[0] = 0xffffffff;  // fake return PC
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer
  100bfc:	29 f9                	sub    %edi,%ecx
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;

  ustack[0] = 0xffffffff;  // fake return PC
  100bfe:	c7 85 04 ff ff ff ff 	movl   $0xffffffff,-0xfc(%ebp)
  100c05:	ff ff ff 
  ustack[1] = argc;
  100c08:	89 b5 08 ff ff ff    	mov    %esi,-0xf8(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
  100c0e:	89 8d 0c ff ff ff    	mov    %ecx,-0xf4(%ebp)

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
  100c14:	89 54 24 08          	mov    %edx,0x8(%esp)
  100c18:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  100c1c:	89 04 24             	mov    %eax,(%esp)
  100c1f:	e8 2c 52 00 00       	call   105e50 <copyout>
  100c24:	85 c0                	test   %eax,%eax
  100c26:	78 8f                	js     100bb7 <exec+0x217>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
  100c28:	8b 4d 08             	mov    0x8(%ebp),%ecx
  100c2b:	0f b6 11             	movzbl (%ecx),%edx
  100c2e:	84 d2                	test   %dl,%dl
  100c30:	74 16                	je     100c48 <exec+0x2a8>
  100c32:	89 c8                	mov    %ecx,%eax
  100c34:	83 c0 01             	add    $0x1,%eax
  100c37:	90                   	nop
    if(*s == '/')
  100c38:	80 fa 2f             	cmp    $0x2f,%dl
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
  100c3b:	0f b6 10             	movzbl (%eax),%edx
    if(*s == '/')
  100c3e:	0f 44 c8             	cmove  %eax,%ecx
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
  100c41:	83 c0 01             	add    $0x1,%eax
  100c44:	84 d2                	test   %dl,%dl
  100c46:	75 f0                	jne    100c38 <exec+0x298>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
  100c48:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  100c4e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  100c52:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  100c59:	00 
  100c5a:	83 c0 6c             	add    $0x6c,%eax
  100c5d:	89 04 24             	mov    %eax,(%esp)
  100c60:	e8 5b 32 00 00       	call   103ec0 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
  100c65:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  proc->pgdir = pgdir;
  100c6b:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));

  // Commit to the user image.
  oldpgdir = proc->pgdir;
  100c71:	8b 70 04             	mov    0x4(%eax),%esi
  proc->pgdir = pgdir;
  100c74:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
  100c77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  100c7d:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
  100c83:	89 08                	mov    %ecx,(%eax)
  proc->tf->eip = elf.entry;  // main
  100c85:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  100c8b:	8b 55 ac             	mov    -0x54(%ebp),%edx
  100c8e:	8b 40 18             	mov    0x18(%eax),%eax
  100c91:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
  100c94:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  100c9a:	8b 40 18             	mov    0x18(%eax),%eax
  100c9d:	89 58 44             	mov    %ebx,0x44(%eax)
  switchuvm(proc);
  100ca0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  100ca6:	89 04 24             	mov    %eax,(%esp)
  100ca9:	e8 52 57 00 00       	call   106400 <switchuvm>
  freevm(oldpgdir);
  100cae:	89 34 24             	mov    %esi,(%esp)
  100cb1:	e8 7a 54 00 00       	call   106130 <freevm>
  100cb6:	31 c0                	xor    %eax,%eax

  return 0;
  100cb8:	e9 2e fe ff ff       	jmp    100aeb <exec+0x14b>
  if((sz = allocuvm(pgdir, sz, sz + PGSIZE)) == 0)
    goto bad;

  // Push argument strings, prepare rest of stack in ustack.
  sp = sz;
  for(argc = 0; argv[argc]; argc++) {
  100cbd:	8b 9d f4 fe ff ff    	mov    -0x10c(%ebp),%ebx
  100cc3:	b0 10                	mov    $0x10,%al
  100cc5:	bf 04 00 00 00       	mov    $0x4,%edi
  100cca:	b9 03 00 00 00       	mov    $0x3,%ecx
  100ccf:	31 f6                	xor    %esi,%esi
  100cd1:	8d 95 04 ff ff ff    	lea    -0xfc(%ebp),%edx
  100cd7:	e9 07 ff ff ff       	jmp    100be3 <exec+0x243>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
  100cdc:	be 00 10 00 00       	mov    $0x1000,%esi
  100ce1:	31 db                	xor    %ebx,%ebx
  100ce3:	e9 28 fe ff ff       	jmp    100b10 <exec+0x170>
  100ce8:	90                   	nop
  100ce9:	90                   	nop
  100cea:	90                   	nop
  100ceb:	90                   	nop
  100cec:	90                   	nop
  100ced:	90                   	nop
  100cee:	90                   	nop
  100cef:	90                   	nop

00100cf0 <filewrite>:
}

// Write to file f.  Addr is kernel address.
int
filewrite(struct file *f, char *addr, int n)
{
  100cf0:	55                   	push   %ebp
  100cf1:	89 e5                	mov    %esp,%ebp
  100cf3:	83 ec 38             	sub    $0x38,%esp
  100cf6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  100cf9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  100cfc:	89 75 f8             	mov    %esi,-0x8(%ebp)
  100cff:	8b 75 0c             	mov    0xc(%ebp),%esi
  100d02:	89 7d fc             	mov    %edi,-0x4(%ebp)
  100d05:	8b 7d 10             	mov    0x10(%ebp),%edi
  int r;

  if(f->writable == 0)
  100d08:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
  100d0c:	74 5a                	je     100d68 <filewrite+0x78>
    return -1;
  if(f->type == FD_PIPE)
  100d0e:	8b 03                	mov    (%ebx),%eax
  100d10:	83 f8 01             	cmp    $0x1,%eax
  100d13:	74 5b                	je     100d70 <filewrite+0x80>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
  100d15:	83 f8 02             	cmp    $0x2,%eax
  100d18:	75 6d                	jne    100d87 <filewrite+0x97>
    ilock(f->ip);
  100d1a:	8b 43 10             	mov    0x10(%ebx),%eax
  100d1d:	89 04 24             	mov    %eax,(%esp)
  100d20:	e8 8b 0e 00 00       	call   101bb0 <ilock>
    if((r = writei(f->ip, addr, f->off, n)) > 0)
  100d25:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  100d29:	8b 43 14             	mov    0x14(%ebx),%eax
  100d2c:	89 74 24 04          	mov    %esi,0x4(%esp)
  100d30:	89 44 24 08          	mov    %eax,0x8(%esp)
  100d34:	8b 43 10             	mov    0x10(%ebx),%eax
  100d37:	89 04 24             	mov    %eax,(%esp)
  100d3a:	e8 c1 07 00 00       	call   101500 <writei>
  100d3f:	85 c0                	test   %eax,%eax
  100d41:	7e 03                	jle    100d46 <filewrite+0x56>
      f->off += r;
  100d43:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
  100d46:	8b 53 10             	mov    0x10(%ebx),%edx
  100d49:	89 14 24             	mov    %edx,(%esp)
  100d4c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d4f:	e8 1c 0a 00 00       	call   101770 <iunlock>
    return r;
  100d54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  }
  panic("filewrite");
}
  100d57:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100d5a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100d5d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  100d60:	89 ec                	mov    %ebp,%esp
  100d62:	5d                   	pop    %ebp
  100d63:	c3                   	ret    
  100d64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if((r = writei(f->ip, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("filewrite");
  100d68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  100d6d:	eb e8                	jmp    100d57 <filewrite+0x67>
  100d6f:	90                   	nop
  int r;

  if(f->writable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return pipewrite(f->pipe, addr, n);
  100d70:	8b 43 0c             	mov    0xc(%ebx),%eax
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("filewrite");
}
  100d73:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100d76:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100d79:	8b 7d fc             	mov    -0x4(%ebp),%edi
  int r;

  if(f->writable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return pipewrite(f->pipe, addr, n);
  100d7c:	89 45 08             	mov    %eax,0x8(%ebp)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("filewrite");
}
  100d7f:	89 ec                	mov    %ebp,%esp
  100d81:	5d                   	pop    %ebp
  int r;

  if(f->writable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return pipewrite(f->pipe, addr, n);
  100d82:	e9 d9 1f 00 00       	jmp    102d60 <pipewrite>
    if((r = writei(f->ip, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("filewrite");
  100d87:	c7 04 24 3f 66 10 00 	movl   $0x10663f,(%esp)
  100d8e:	e8 8d fb ff ff       	call   100920 <panic>
  100d93:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  100d99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100da0 <fileread>:
}

// Read from file f.  Addr is kernel address.
int
fileread(struct file *f, char *addr, int n)
{
  100da0:	55                   	push   %ebp
  100da1:	89 e5                	mov    %esp,%ebp
  100da3:	83 ec 38             	sub    $0x38,%esp
  100da6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  100da9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  100dac:	89 75 f8             	mov    %esi,-0x8(%ebp)
  100daf:	8b 75 0c             	mov    0xc(%ebp),%esi
  100db2:	89 7d fc             	mov    %edi,-0x4(%ebp)
  100db5:	8b 7d 10             	mov    0x10(%ebp),%edi
  int r;

  if(f->readable == 0)
  100db8:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
  100dbc:	74 5a                	je     100e18 <fileread+0x78>
    return -1;
  if(f->type == FD_PIPE)
  100dbe:	8b 03                	mov    (%ebx),%eax
  100dc0:	83 f8 01             	cmp    $0x1,%eax
  100dc3:	74 5b                	je     100e20 <fileread+0x80>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
  100dc5:	83 f8 02             	cmp    $0x2,%eax
  100dc8:	75 6d                	jne    100e37 <fileread+0x97>
    ilock(f->ip);
  100dca:	8b 43 10             	mov    0x10(%ebx),%eax
  100dcd:	89 04 24             	mov    %eax,(%esp)
  100dd0:	e8 db 0d 00 00       	call   101bb0 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
  100dd5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  100dd9:	8b 43 14             	mov    0x14(%ebx),%eax
  100ddc:	89 74 24 04          	mov    %esi,0x4(%esp)
  100de0:	89 44 24 08          	mov    %eax,0x8(%esp)
  100de4:	8b 43 10             	mov    0x10(%ebx),%eax
  100de7:	89 04 24             	mov    %eax,(%esp)
  100dea:	e8 71 05 00 00       	call   101360 <readi>
  100def:	85 c0                	test   %eax,%eax
  100df1:	7e 03                	jle    100df6 <fileread+0x56>
      f->off += r;
  100df3:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
  100df6:	8b 53 10             	mov    0x10(%ebx),%edx
  100df9:	89 14 24             	mov    %edx,(%esp)
  100dfc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100dff:	e8 6c 09 00 00       	call   101770 <iunlock>
    return r;
  100e04:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  }
  panic("fileread");
}
  100e07:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100e0a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100e0d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  100e10:	89 ec                	mov    %ebp,%esp
  100e12:	5d                   	pop    %ebp
  100e13:	c3                   	ret    
  100e14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if((r = readi(f->ip, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("fileread");
  100e18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  100e1d:	eb e8                	jmp    100e07 <fileread+0x67>
  100e1f:	90                   	nop
  int r;

  if(f->readable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return piperead(f->pipe, addr, n);
  100e20:	8b 43 0c             	mov    0xc(%ebx),%eax
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("fileread");
}
  100e23:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100e26:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100e29:	8b 7d fc             	mov    -0x4(%ebp),%edi
  int r;

  if(f->readable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return piperead(f->pipe, addr, n);
  100e2c:	89 45 08             	mov    %eax,0x8(%ebp)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("fileread");
}
  100e2f:	89 ec                	mov    %ebp,%esp
  100e31:	5d                   	pop    %ebp
  int r;

  if(f->readable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return piperead(f->pipe, addr, n);
  100e32:	e9 29 1e 00 00       	jmp    102c60 <piperead>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("fileread");
  100e37:	c7 04 24 49 66 10 00 	movl   $0x106649,(%esp)
  100e3e:	e8 dd fa ff ff       	call   100920 <panic>
  100e43:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  100e49:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100e50 <filestat>:
}

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
  100e50:	55                   	push   %ebp
  if(f->type == FD_INODE){
  100e51:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
  100e56:	89 e5                	mov    %esp,%ebp
  100e58:	53                   	push   %ebx
  100e59:	83 ec 14             	sub    $0x14,%esp
  100e5c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
  100e5f:	83 3b 02             	cmpl   $0x2,(%ebx)
  100e62:	74 0c                	je     100e70 <filestat+0x20>
    stati(f->ip, st);
    iunlock(f->ip);
    return 0;
  }
  return -1;
}
  100e64:	83 c4 14             	add    $0x14,%esp
  100e67:	5b                   	pop    %ebx
  100e68:	5d                   	pop    %ebp
  100e69:	c3                   	ret    
  100e6a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
  if(f->type == FD_INODE){
    ilock(f->ip);
  100e70:	8b 43 10             	mov    0x10(%ebx),%eax
  100e73:	89 04 24             	mov    %eax,(%esp)
  100e76:	e8 35 0d 00 00       	call   101bb0 <ilock>
    stati(f->ip, st);
  100e7b:	8b 45 0c             	mov    0xc(%ebp),%eax
  100e7e:	89 44 24 04          	mov    %eax,0x4(%esp)
  100e82:	8b 43 10             	mov    0x10(%ebx),%eax
  100e85:	89 04 24             	mov    %eax,(%esp)
  100e88:	e8 e3 01 00 00       	call   101070 <stati>
    iunlock(f->ip);
  100e8d:	8b 43 10             	mov    0x10(%ebx),%eax
  100e90:	89 04 24             	mov    %eax,(%esp)
  100e93:	e8 d8 08 00 00       	call   101770 <iunlock>
    return 0;
  }
  return -1;
}
  100e98:	83 c4 14             	add    $0x14,%esp
filestat(struct file *f, struct stat *st)
{
  if(f->type == FD_INODE){
    ilock(f->ip);
    stati(f->ip, st);
    iunlock(f->ip);
  100e9b:	31 c0                	xor    %eax,%eax
    return 0;
  }
  return -1;
}
  100e9d:	5b                   	pop    %ebx
  100e9e:	5d                   	pop    %ebp
  100e9f:	c3                   	ret    

00100ea0 <filedup>:
}

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
  100ea0:	55                   	push   %ebp
  100ea1:	89 e5                	mov    %esp,%ebp
  100ea3:	53                   	push   %ebx
  100ea4:	83 ec 14             	sub    $0x14,%esp
  100ea7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
  100eaa:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100eb1:	e8 ca 2d 00 00       	call   103c80 <acquire>
  if(f->ref < 1)
  100eb6:	8b 43 04             	mov    0x4(%ebx),%eax
  100eb9:	85 c0                	test   %eax,%eax
  100ebb:	7e 1a                	jle    100ed7 <filedup+0x37>
    panic("filedup");
  f->ref++;
  100ebd:	83 c0 01             	add    $0x1,%eax
  100ec0:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
  100ec3:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100eca:	e8 61 2d 00 00       	call   103c30 <release>
  return f;
}
  100ecf:	89 d8                	mov    %ebx,%eax
  100ed1:	83 c4 14             	add    $0x14,%esp
  100ed4:	5b                   	pop    %ebx
  100ed5:	5d                   	pop    %ebp
  100ed6:	c3                   	ret    
struct file*
filedup(struct file *f)
{
  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("filedup");
  100ed7:	c7 04 24 52 66 10 00 	movl   $0x106652,(%esp)
  100ede:	e8 3d fa ff ff       	call   100920 <panic>
  100ee3:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  100ee9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100ef0 <filealloc>:
}

// Allocate a file structure.
struct file*
filealloc(void)
{
  100ef0:	55                   	push   %ebp
  100ef1:	89 e5                	mov    %esp,%ebp
  100ef3:	53                   	push   %ebx
  initlock(&ftable.lock, "ftable");
}

// Allocate a file structure.
struct file*
filealloc(void)
  100ef4:	bb 2c a1 10 00       	mov    $0x10a12c,%ebx
{
  100ef9:	83 ec 14             	sub    $0x14,%esp
  struct file *f;

  acquire(&ftable.lock);
  100efc:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100f03:	e8 78 2d 00 00       	call   103c80 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
  100f08:	8b 15 18 a1 10 00    	mov    0x10a118,%edx
  100f0e:	85 d2                	test   %edx,%edx
  100f10:	75 11                	jne    100f23 <filealloc+0x33>
  100f12:	eb 4a                	jmp    100f5e <filealloc+0x6e>
  100f14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
  100f18:	83 c3 18             	add    $0x18,%ebx
  100f1b:	81 fb 74 aa 10 00    	cmp    $0x10aa74,%ebx
  100f21:	74 25                	je     100f48 <filealloc+0x58>
    if(f->ref == 0){
  100f23:	8b 43 04             	mov    0x4(%ebx),%eax
  100f26:	85 c0                	test   %eax,%eax
  100f28:	75 ee                	jne    100f18 <filealloc+0x28>
      f->ref = 1;
  100f2a:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
  100f31:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100f38:	e8 f3 2c 00 00       	call   103c30 <release>
      return f;
    }
  }
  release(&ftable.lock);
  return 0;
}
  100f3d:	89 d8                	mov    %ebx,%eax
  100f3f:	83 c4 14             	add    $0x14,%esp
  100f42:	5b                   	pop    %ebx
  100f43:	5d                   	pop    %ebp
  100f44:	c3                   	ret    
  100f45:	8d 76 00             	lea    0x0(%esi),%esi
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
  100f48:	31 db                	xor    %ebx,%ebx
  100f4a:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100f51:	e8 da 2c 00 00       	call   103c30 <release>
  return 0;
}
  100f56:	89 d8                	mov    %ebx,%eax
  100f58:	83 c4 14             	add    $0x14,%esp
  100f5b:	5b                   	pop    %ebx
  100f5c:	5d                   	pop    %ebp
  100f5d:	c3                   	ret    
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
  100f5e:	bb 14 a1 10 00       	mov    $0x10a114,%ebx
  100f63:	eb c5                	jmp    100f2a <filealloc+0x3a>
  100f65:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  100f69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00100f70 <fileclose>:
}

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
  100f70:	55                   	push   %ebp
  100f71:	89 e5                	mov    %esp,%ebp
  100f73:	83 ec 38             	sub    $0x38,%esp
  100f76:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  100f79:	8b 5d 08             	mov    0x8(%ebp),%ebx
  100f7c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  100f7f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  struct file ff;

  acquire(&ftable.lock);
  100f82:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100f89:	e8 f2 2c 00 00       	call   103c80 <acquire>
  if(f->ref < 1)
  100f8e:	8b 43 04             	mov    0x4(%ebx),%eax
  100f91:	85 c0                	test   %eax,%eax
  100f93:	0f 8e 9c 00 00 00    	jle    101035 <fileclose+0xc5>
    panic("fileclose");
  if(--f->ref > 0){
  100f99:	83 e8 01             	sub    $0x1,%eax
  100f9c:	85 c0                	test   %eax,%eax
  100f9e:	89 43 04             	mov    %eax,0x4(%ebx)
  100fa1:	74 1d                	je     100fc0 <fileclose+0x50>
    release(&ftable.lock);
  100fa3:	c7 45 08 e0 a0 10 00 	movl   $0x10a0e0,0x8(%ebp)
  
  if(ff.type == FD_PIPE)
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE)
    iput(ff.ip);
}
  100faa:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100fad:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100fb0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  100fb3:	89 ec                	mov    %ebp,%esp
  100fb5:	5d                   	pop    %ebp

  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("fileclose");
  if(--f->ref > 0){
    release(&ftable.lock);
  100fb6:	e9 75 2c 00 00       	jmp    103c30 <release>
  100fbb:	90                   	nop
  100fbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    return;
  }
  ff = *f;
  100fc0:	8b 43 0c             	mov    0xc(%ebx),%eax
  100fc3:	8b 7b 10             	mov    0x10(%ebx),%edi
  100fc6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100fc9:	0f b6 43 09          	movzbl 0x9(%ebx),%eax
  100fcd:	88 45 e7             	mov    %al,-0x19(%ebp)
  100fd0:	8b 33                	mov    (%ebx),%esi
  f->ref = 0;
  100fd2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
  100fd9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
  100fdf:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  100fe6:	e8 45 2c 00 00       	call   103c30 <release>
  
  if(ff.type == FD_PIPE)
  100feb:	83 fe 01             	cmp    $0x1,%esi
  100fee:	74 30                	je     101020 <fileclose+0xb0>
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE)
  100ff0:	83 fe 02             	cmp    $0x2,%esi
  100ff3:	74 13                	je     101008 <fileclose+0x98>
    iput(ff.ip);
}
  100ff5:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  100ff8:	8b 75 f8             	mov    -0x8(%ebp),%esi
  100ffb:	8b 7d fc             	mov    -0x4(%ebp),%edi
  100ffe:	89 ec                	mov    %ebp,%esp
  101000:	5d                   	pop    %ebp
  101001:	c3                   	ret    
  101002:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  release(&ftable.lock);
  
  if(ff.type == FD_PIPE)
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE)
    iput(ff.ip);
  101008:	89 7d 08             	mov    %edi,0x8(%ebp)
}
  10100b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10100e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  101011:	8b 7d fc             	mov    -0x4(%ebp),%edi
  101014:	89 ec                	mov    %ebp,%esp
  101016:	5d                   	pop    %ebp
  release(&ftable.lock);
  
  if(ff.type == FD_PIPE)
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE)
    iput(ff.ip);
  101017:	e9 64 08 00 00       	jmp    101880 <iput>
  10101c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  f->ref = 0;
  f->type = FD_NONE;
  release(&ftable.lock);
  
  if(ff.type == FD_PIPE)
    pipeclose(ff.pipe, ff.writable);
  101020:	0f be 45 e7          	movsbl -0x19(%ebp),%eax
  101024:	89 44 24 04          	mov    %eax,0x4(%esp)
  101028:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10102b:	89 04 24             	mov    %eax,(%esp)
  10102e:	e8 1d 1e 00 00       	call   102e50 <pipeclose>
  101033:	eb c0                	jmp    100ff5 <fileclose+0x85>
{
  struct file ff;

  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("fileclose");
  101035:	c7 04 24 5a 66 10 00 	movl   $0x10665a,(%esp)
  10103c:	e8 df f8 ff ff       	call   100920 <panic>
  101041:	eb 0d                	jmp    101050 <fileinit>
  101043:	90                   	nop
  101044:	90                   	nop
  101045:	90                   	nop
  101046:	90                   	nop
  101047:	90                   	nop
  101048:	90                   	nop
  101049:	90                   	nop
  10104a:	90                   	nop
  10104b:	90                   	nop
  10104c:	90                   	nop
  10104d:	90                   	nop
  10104e:	90                   	nop
  10104f:	90                   	nop

00101050 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
  101050:	55                   	push   %ebp
  101051:	89 e5                	mov    %esp,%ebp
  101053:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
  101056:	c7 44 24 04 64 66 10 	movl   $0x106664,0x4(%esp)
  10105d:	00 
  10105e:	c7 04 24 e0 a0 10 00 	movl   $0x10a0e0,(%esp)
  101065:	e8 86 2a 00 00       	call   103af0 <initlock>
}
  10106a:	c9                   	leave  
  10106b:	c3                   	ret    
  10106c:	90                   	nop
  10106d:	90                   	nop
  10106e:	90                   	nop
  10106f:	90                   	nop

00101070 <stati>:
}

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
  101070:	55                   	push   %ebp
  101071:	89 e5                	mov    %esp,%ebp
  101073:	8b 55 08             	mov    0x8(%ebp),%edx
  101076:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
  101079:	8b 0a                	mov    (%edx),%ecx
  10107b:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
  10107e:	8b 4a 04             	mov    0x4(%edx),%ecx
  101081:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
  101084:	0f b7 4a 10          	movzwl 0x10(%edx),%ecx
  101088:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
  10108b:	0f b7 4a 16          	movzwl 0x16(%edx),%ecx
  10108f:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
  101093:	8b 52 18             	mov    0x18(%edx),%edx
  101096:	89 50 10             	mov    %edx,0x10(%eax)
}
  101099:	5d                   	pop    %ebp
  10109a:	c3                   	ret    
  10109b:	90                   	nop
  10109c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

001010a0 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
  1010a0:	55                   	push   %ebp
  1010a1:	89 e5                	mov    %esp,%ebp
  1010a3:	53                   	push   %ebx
  1010a4:	83 ec 14             	sub    $0x14,%esp
  1010a7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
  1010aa:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  1010b1:	e8 ca 2b 00 00       	call   103c80 <acquire>
  ip->ref++;
  1010b6:	83 43 08 01          	addl   $0x1,0x8(%ebx)
  release(&icache.lock);
  1010ba:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  1010c1:	e8 6a 2b 00 00       	call   103c30 <release>
  return ip;
}
  1010c6:	89 d8                	mov    %ebx,%eax
  1010c8:	83 c4 14             	add    $0x14,%esp
  1010cb:	5b                   	pop    %ebx
  1010cc:	5d                   	pop    %ebp
  1010cd:	c3                   	ret    
  1010ce:	66 90                	xchg   %ax,%ax

001010d0 <iget>:

// Find the inode with number inum on device dev
// and return the in-memory copy.
static struct inode*
iget(uint dev, uint inum)
{
  1010d0:	55                   	push   %ebp
  1010d1:	89 e5                	mov    %esp,%ebp
  1010d3:	57                   	push   %edi
  1010d4:	89 d7                	mov    %edx,%edi
  1010d6:	56                   	push   %esi
}

// Find the inode with number inum on device dev
// and return the in-memory copy.
static struct inode*
iget(uint dev, uint inum)
  1010d7:	31 f6                	xor    %esi,%esi
{
  1010d9:	53                   	push   %ebx
  1010da:	89 c3                	mov    %eax,%ebx
  1010dc:	83 ec 2c             	sub    $0x2c,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
  1010df:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  1010e6:	e8 95 2b 00 00       	call   103c80 <acquire>
}

// Find the inode with number inum on device dev
// and return the in-memory copy.
static struct inode*
iget(uint dev, uint inum)
  1010eb:	b8 14 ab 10 00       	mov    $0x10ab14,%eax
  1010f0:	eb 14                	jmp    101106 <iget+0x36>
  1010f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
      ip->ref++;
      release(&icache.lock);
      return ip;
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
  1010f8:	85 f6                	test   %esi,%esi
  1010fa:	74 3c                	je     101138 <iget+0x68>

  acquire(&icache.lock);

  // Try for cached inode.
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
  1010fc:	83 c0 50             	add    $0x50,%eax
  1010ff:	3d b4 ba 10 00       	cmp    $0x10bab4,%eax
  101104:	74 42                	je     101148 <iget+0x78>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
  101106:	8b 48 08             	mov    0x8(%eax),%ecx
  101109:	85 c9                	test   %ecx,%ecx
  10110b:	7e eb                	jle    1010f8 <iget+0x28>
  10110d:	39 18                	cmp    %ebx,(%eax)
  10110f:	75 e7                	jne    1010f8 <iget+0x28>
  101111:	39 78 04             	cmp    %edi,0x4(%eax)
  101114:	75 e2                	jne    1010f8 <iget+0x28>
      ip->ref++;
  101116:	83 c1 01             	add    $0x1,%ecx
  101119:	89 48 08             	mov    %ecx,0x8(%eax)
      release(&icache.lock);
  10111c:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101123:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  101126:	e8 05 2b 00 00       	call   103c30 <release>
      return ip;
  10112b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  ip->ref = 1;
  ip->flags = 0;
  release(&icache.lock);

  return ip;
}
  10112e:	83 c4 2c             	add    $0x2c,%esp
  101131:	5b                   	pop    %ebx
  101132:	5e                   	pop    %esi
  101133:	5f                   	pop    %edi
  101134:	5d                   	pop    %ebp
  101135:	c3                   	ret    
  101136:	66 90                	xchg   %ax,%ax
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
      ip->ref++;
      release(&icache.lock);
      return ip;
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
  101138:	85 c9                	test   %ecx,%ecx
  10113a:	0f 44 f0             	cmove  %eax,%esi

  acquire(&icache.lock);

  // Try for cached inode.
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
  10113d:	83 c0 50             	add    $0x50,%eax
  101140:	3d b4 ba 10 00       	cmp    $0x10bab4,%eax
  101145:	75 bf                	jne    101106 <iget+0x36>
  101147:	90                   	nop
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Allocate fresh inode.
  if(empty == 0)
  101148:	85 f6                	test   %esi,%esi
  10114a:	74 29                	je     101175 <iget+0xa5>
    panic("iget: no inodes");

  ip = empty;
  ip->dev = dev;
  10114c:	89 1e                	mov    %ebx,(%esi)
  ip->inum = inum;
  10114e:	89 7e 04             	mov    %edi,0x4(%esi)
  ip->ref = 1;
  101151:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->flags = 0;
  101158:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
  release(&icache.lock);
  10115f:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101166:	e8 c5 2a 00 00       	call   103c30 <release>

  return ip;
}
  10116b:	83 c4 2c             	add    $0x2c,%esp
  ip = empty;
  ip->dev = dev;
  ip->inum = inum;
  ip->ref = 1;
  ip->flags = 0;
  release(&icache.lock);
  10116e:	89 f0                	mov    %esi,%eax

  return ip;
}
  101170:	5b                   	pop    %ebx
  101171:	5e                   	pop    %esi
  101172:	5f                   	pop    %edi
  101173:	5d                   	pop    %ebp
  101174:	c3                   	ret    
      empty = ip;
  }

  // Allocate fresh inode.
  if(empty == 0)
    panic("iget: no inodes");
  101175:	c7 04 24 6b 66 10 00 	movl   $0x10666b,(%esp)
  10117c:	e8 9f f7 ff ff       	call   100920 <panic>
  101181:	eb 0d                	jmp    101190 <readsb>
  101183:	90                   	nop
  101184:	90                   	nop
  101185:	90                   	nop
  101186:	90                   	nop
  101187:	90                   	nop
  101188:	90                   	nop
  101189:	90                   	nop
  10118a:	90                   	nop
  10118b:	90                   	nop
  10118c:	90                   	nop
  10118d:	90                   	nop
  10118e:	90                   	nop
  10118f:	90                   	nop

00101190 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
static void
readsb(int dev, struct superblock *sb)
{
  101190:	55                   	push   %ebp
  101191:	89 e5                	mov    %esp,%ebp
  101193:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
  101196:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10119d:	00 
static void itrunc(struct inode*);

// Read the super block.
static void
readsb(int dev, struct superblock *sb)
{
  10119e:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  1011a1:	89 75 fc             	mov    %esi,-0x4(%ebp)
  1011a4:	89 d6                	mov    %edx,%esi
  struct buf *bp;
  
  bp = bread(dev, 1);
  1011a6:	89 04 24             	mov    %eax,(%esp)
  1011a9:	e8 72 ef ff ff       	call   100120 <bread>
  memmove(sb, bp->data, sizeof(*sb));
  1011ae:	89 34 24             	mov    %esi,(%esp)
  1011b1:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
  1011b8:	00 
static void
readsb(int dev, struct superblock *sb)
{
  struct buf *bp;
  
  bp = bread(dev, 1);
  1011b9:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
  1011bb:	83 c0 18             	add    $0x18,%eax
  1011be:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011c2:	e8 d9 2b 00 00       	call   103da0 <memmove>
  brelse(bp);
  1011c7:	89 1c 24             	mov    %ebx,(%esp)
  1011ca:	e8 a1 ee ff ff       	call   100070 <brelse>
}
  1011cf:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  1011d2:	8b 75 fc             	mov    -0x4(%ebp),%esi
  1011d5:	89 ec                	mov    %ebp,%esp
  1011d7:	5d                   	pop    %ebp
  1011d8:	c3                   	ret    
  1011d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

001011e0 <balloc>:
// Blocks. 

// Allocate a disk block.
static uint
balloc(uint dev)
{
  1011e0:	55                   	push   %ebp
  1011e1:	89 e5                	mov    %esp,%ebp
  1011e3:	57                   	push   %edi
  1011e4:	56                   	push   %esi
  1011e5:	53                   	push   %ebx
  1011e6:	83 ec 3c             	sub    $0x3c,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  1011e9:	8d 55 dc             	lea    -0x24(%ebp),%edx
// Blocks. 

// Allocate a disk block.
static uint
balloc(uint dev)
{
  1011ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  1011ef:	e8 9c ff ff ff       	call   101190 <readsb>
  for(b = 0; b < sb.size; b += BPB){
  1011f4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1011f7:	85 c0                	test   %eax,%eax
  1011f9:	0f 84 9c 00 00 00    	je     10129b <balloc+0xbb>
  1011ff:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
    bp = bread(dev, BBLOCK(b, sb.ninodes));
  101206:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101209:	31 db                	xor    %ebx,%ebx
  10120b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10120e:	c1 e8 03             	shr    $0x3,%eax
  101211:	c1 fa 0c             	sar    $0xc,%edx
  101214:	8d 44 10 03          	lea    0x3(%eax,%edx,1),%eax
  101218:	89 44 24 04          	mov    %eax,0x4(%esp)
  10121c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10121f:	89 04 24             	mov    %eax,(%esp)
  101222:	e8 f9 ee ff ff       	call   100120 <bread>
  101227:	89 c6                	mov    %eax,%esi
  101229:	eb 10                	jmp    10123b <balloc+0x5b>
  10122b:	90                   	nop
  10122c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    for(bi = 0; bi < BPB; bi++){
  101230:	83 c3 01             	add    $0x1,%ebx
  101233:	81 fb 00 10 00 00    	cmp    $0x1000,%ebx
  101239:	74 45                	je     101280 <balloc+0xa0>
      m = 1 << (bi % 8);
  10123b:	89 d9                	mov    %ebx,%ecx
  10123d:	b8 01 00 00 00       	mov    $0x1,%eax
  101242:	83 e1 07             	and    $0x7,%ecx
  101245:	d3 e0                	shl    %cl,%eax
  101247:	89 c1                	mov    %eax,%ecx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
  101249:	89 d8                	mov    %ebx,%eax
  10124b:	c1 f8 03             	sar    $0x3,%eax
  10124e:	0f b6 54 06 18       	movzbl 0x18(%esi,%eax,1),%edx
  101253:	0f b6 fa             	movzbl %dl,%edi
  101256:	85 cf                	test   %ecx,%edi
  101258:	75 d6                	jne    101230 <balloc+0x50>
        bp->data[bi/8] |= m;  // Mark block in use on disk.
  10125a:	09 d1                	or     %edx,%ecx
  10125c:	88 4c 06 18          	mov    %cl,0x18(%esi,%eax,1)
        bwrite(bp);
  101260:	89 34 24             	mov    %esi,(%esp)
  101263:	e8 88 ee ff ff       	call   1000f0 <bwrite>
        brelse(bp);
  101268:	89 34 24             	mov    %esi,(%esp)
  10126b:	e8 00 ee ff ff       	call   100070 <brelse>
  101270:	8b 45 d4             	mov    -0x2c(%ebp),%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
  101273:	83 c4 3c             	add    $0x3c,%esp
    for(bi = 0; bi < BPB; bi++){
      m = 1 << (bi % 8);
      if((bp->data[bi/8] & m) == 0){  // Is block free?
        bp->data[bi/8] |= m;  // Mark block in use on disk.
        bwrite(bp);
        brelse(bp);
  101276:	8d 04 03             	lea    (%ebx,%eax,1),%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
  101279:	5b                   	pop    %ebx
  10127a:	5e                   	pop    %esi
  10127b:	5f                   	pop    %edi
  10127c:	5d                   	pop    %ebp
  10127d:	c3                   	ret    
  10127e:	66 90                	xchg   %ax,%ax
        bwrite(bp);
        brelse(bp);
        return b + bi;
      }
    }
    brelse(bp);
  101280:	89 34 24             	mov    %esi,(%esp)
  101283:	e8 e8 ed ff ff       	call   100070 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
  101288:	81 45 d4 00 10 00 00 	addl   $0x1000,-0x2c(%ebp)
  10128f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  101292:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  101295:	0f 87 6b ff ff ff    	ja     101206 <balloc+0x26>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
  10129b:	c7 04 24 7b 66 10 00 	movl   $0x10667b,(%esp)
  1012a2:	e8 79 f6 ff ff       	call   100920 <panic>
  1012a7:	89 f6                	mov    %esi,%esi
  1012a9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001012b0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
  1012b0:	55                   	push   %ebp
  1012b1:	89 e5                	mov    %esp,%ebp
  1012b3:	83 ec 38             	sub    $0x38,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
  1012b6:	83 fa 0b             	cmp    $0xb,%edx

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
  1012b9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  1012bc:	89 c3                	mov    %eax,%ebx
  1012be:	89 75 f8             	mov    %esi,-0x8(%ebp)
  1012c1:	89 7d fc             	mov    %edi,-0x4(%ebp)
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
  1012c4:	77 1a                	ja     1012e0 <bmap+0x30>
    if((addr = ip->addrs[bn]) == 0)
  1012c6:	8d 7a 04             	lea    0x4(%edx),%edi
  1012c9:	8b 44 b8 0c          	mov    0xc(%eax,%edi,4),%eax
  1012cd:	85 c0                	test   %eax,%eax
  1012cf:	74 5f                	je     101330 <bmap+0x80>
    brelse(bp);
    return addr;
  }

  panic("bmap: out of range");
}
  1012d1:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  1012d4:	8b 75 f8             	mov    -0x8(%ebp),%esi
  1012d7:	8b 7d fc             	mov    -0x4(%ebp),%edi
  1012da:	89 ec                	mov    %ebp,%esp
  1012dc:	5d                   	pop    %ebp
  1012dd:	c3                   	ret    
  1012de:	66 90                	xchg   %ax,%ax
  if(bn < NDIRECT){
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
  1012e0:	8d 7a f4             	lea    -0xc(%edx),%edi

  if(bn < NINDIRECT){
  1012e3:	83 ff 7f             	cmp    $0x7f,%edi
  1012e6:	77 64                	ja     10134c <bmap+0x9c>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
  1012e8:	8b 40 4c             	mov    0x4c(%eax),%eax
  1012eb:	85 c0                	test   %eax,%eax
  1012ed:	74 51                	je     101340 <bmap+0x90>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
  1012ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012f3:	8b 03                	mov    (%ebx),%eax
  1012f5:	89 04 24             	mov    %eax,(%esp)
  1012f8:	e8 23 ee ff ff       	call   100120 <bread>
    a = (uint*)bp->data;
    if((addr = a[bn]) == 0){
  1012fd:	8d 7c b8 18          	lea    0x18(%eax,%edi,4),%edi

  if(bn < NINDIRECT){
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
  101301:	89 c6                	mov    %eax,%esi
    a = (uint*)bp->data;
    if((addr = a[bn]) == 0){
  101303:	8b 07                	mov    (%edi),%eax
  101305:	85 c0                	test   %eax,%eax
  101307:	75 17                	jne    101320 <bmap+0x70>
      a[bn] = addr = balloc(ip->dev);
  101309:	8b 03                	mov    (%ebx),%eax
  10130b:	e8 d0 fe ff ff       	call   1011e0 <balloc>
  101310:	89 07                	mov    %eax,(%edi)
      bwrite(bp);
  101312:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  101315:	89 34 24             	mov    %esi,(%esp)
  101318:	e8 d3 ed ff ff       	call   1000f0 <bwrite>
  10131d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    }
    brelse(bp);
  101320:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  101323:	89 34 24             	mov    %esi,(%esp)
  101326:	e8 45 ed ff ff       	call   100070 <brelse>
    return addr;
  10132b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10132e:	eb a1                	jmp    1012d1 <bmap+0x21>
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
  101330:	8b 03                	mov    (%ebx),%eax
  101332:	e8 a9 fe ff ff       	call   1011e0 <balloc>
  101337:	89 44 bb 0c          	mov    %eax,0xc(%ebx,%edi,4)
  10133b:	eb 94                	jmp    1012d1 <bmap+0x21>
  10133d:	8d 76 00             	lea    0x0(%esi),%esi
  bn -= NDIRECT;

  if(bn < NINDIRECT){
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
  101340:	8b 03                	mov    (%ebx),%eax
  101342:	e8 99 fe ff ff       	call   1011e0 <balloc>
  101347:	89 43 4c             	mov    %eax,0x4c(%ebx)
  10134a:	eb a3                	jmp    1012ef <bmap+0x3f>
    }
    brelse(bp);
    return addr;
  }

  panic("bmap: out of range");
  10134c:	c7 04 24 91 66 10 00 	movl   $0x106691,(%esp)
  101353:	e8 c8 f5 ff ff       	call   100920 <panic>
  101358:	90                   	nop
  101359:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00101360 <readi>:
}

// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
  101360:	55                   	push   %ebp
  101361:	89 e5                	mov    %esp,%ebp
  101363:	83 ec 38             	sub    $0x38,%esp
  101366:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  101369:	8b 5d 08             	mov    0x8(%ebp),%ebx
  10136c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  10136f:	8b 4d 14             	mov    0x14(%ebp),%ecx
  101372:	89 7d fc             	mov    %edi,-0x4(%ebp)
  101375:	8b 75 10             	mov    0x10(%ebp),%esi
  101378:	8b 7d 0c             	mov    0xc(%ebp),%edi
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
  10137b:	66 83 7b 10 03       	cmpw   $0x3,0x10(%ebx)
  101380:	74 1e                	je     1013a0 <readi+0x40>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
      return -1;
    return devsw[ip->major].read(ip, dst, n);
  }

  if(off > ip->size || off + n < off)
  101382:	8b 43 18             	mov    0x18(%ebx),%eax
  101385:	39 f0                	cmp    %esi,%eax
  101387:	73 3f                	jae    1013c8 <readi+0x68>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
  101389:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  10138e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  101391:	8b 75 f8             	mov    -0x8(%ebp),%esi
  101394:	8b 7d fc             	mov    -0x4(%ebp),%edi
  101397:	89 ec                	mov    %ebp,%esp
  101399:	5d                   	pop    %ebp
  10139a:	c3                   	ret    
  10139b:	90                   	nop
  10139c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
  1013a0:	0f b7 43 12          	movzwl 0x12(%ebx),%eax
  1013a4:	66 83 f8 09          	cmp    $0x9,%ax
  1013a8:	77 df                	ja     101389 <readi+0x29>
  1013aa:	98                   	cwtl   
  1013ab:	8b 04 c5 80 aa 10 00 	mov    0x10aa80(,%eax,8),%eax
  1013b2:	85 c0                	test   %eax,%eax
  1013b4:	74 d3                	je     101389 <readi+0x29>
      return -1;
    return devsw[ip->major].read(ip, dst, n);
  1013b6:	89 4d 10             	mov    %ecx,0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
}
  1013b9:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  1013bc:	8b 75 f8             	mov    -0x8(%ebp),%esi
  1013bf:	8b 7d fc             	mov    -0x4(%ebp),%edi
  1013c2:	89 ec                	mov    %ebp,%esp
  1013c4:	5d                   	pop    %ebp
  struct buf *bp;

  if(ip->type == T_DEV){
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
      return -1;
    return devsw[ip->major].read(ip, dst, n);
  1013c5:	ff e0                	jmp    *%eax
  1013c7:	90                   	nop
  }

  if(off > ip->size || off + n < off)
  1013c8:	89 ca                	mov    %ecx,%edx
  1013ca:	01 f2                	add    %esi,%edx
  1013cc:	89 55 e0             	mov    %edx,-0x20(%ebp)
  1013cf:	72 b8                	jb     101389 <readi+0x29>
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;
  1013d1:	89 c2                	mov    %eax,%edx
  1013d3:	29 f2                	sub    %esi,%edx
  1013d5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  1013d8:	0f 42 ca             	cmovb  %edx,%ecx

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
  1013db:	85 c9                	test   %ecx,%ecx
  1013dd:	74 7e                	je     10145d <readi+0xfd>
  1013df:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
  1013e6:	89 7d e0             	mov    %edi,-0x20(%ebp)
  1013e9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  1013ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  1013f0:	89 f2                	mov    %esi,%edx
  1013f2:	89 d8                	mov    %ebx,%eax
  1013f4:	c1 ea 09             	shr    $0x9,%edx
    m = min(n - tot, BSIZE - off%BSIZE);
  1013f7:	bf 00 02 00 00       	mov    $0x200,%edi
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  1013fc:	e8 af fe ff ff       	call   1012b0 <bmap>
  101401:	89 44 24 04          	mov    %eax,0x4(%esp)
  101405:	8b 03                	mov    (%ebx),%eax
  101407:	89 04 24             	mov    %eax,(%esp)
  10140a:	e8 11 ed ff ff       	call   100120 <bread>
    m = min(n - tot, BSIZE - off%BSIZE);
  10140f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  101412:	2b 4d e4             	sub    -0x1c(%ebp),%ecx
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  101415:	89 c2                	mov    %eax,%edx
    m = min(n - tot, BSIZE - off%BSIZE);
  101417:	89 f0                	mov    %esi,%eax
  101419:	25 ff 01 00 00       	and    $0x1ff,%eax
  10141e:	29 c7                	sub    %eax,%edi
  101420:	39 cf                	cmp    %ecx,%edi
  101422:	0f 47 f9             	cmova  %ecx,%edi
    memmove(dst, bp->data + off%BSIZE, m);
  101425:	8d 44 02 18          	lea    0x18(%edx,%eax,1),%eax
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
  101429:	01 fe                	add    %edi,%esi
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
  10142b:	89 7c 24 08          	mov    %edi,0x8(%esp)
  10142f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101433:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101436:	89 04 24             	mov    %eax,(%esp)
  101439:	89 55 d8             	mov    %edx,-0x28(%ebp)
  10143c:	e8 5f 29 00 00       	call   103da0 <memmove>
    brelse(bp);
  101441:	8b 55 d8             	mov    -0x28(%ebp),%edx
  101444:	89 14 24             	mov    %edx,(%esp)
  101447:	e8 24 ec ff ff       	call   100070 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
  10144c:	01 7d e4             	add    %edi,-0x1c(%ebp)
  10144f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101452:	01 7d e0             	add    %edi,-0x20(%ebp)
  101455:	39 55 dc             	cmp    %edx,-0x24(%ebp)
  101458:	77 96                	ja     1013f0 <readi+0x90>
  10145a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
  10145d:	89 c8                	mov    %ecx,%eax
  10145f:	e9 2a ff ff ff       	jmp    10138e <readi+0x2e>
  101464:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  10146a:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00101470 <iupdate>:
}

// Copy inode, which has changed, from memory to disk.
void
iupdate(struct inode *ip)
{
  101470:	55                   	push   %ebp
  101471:	89 e5                	mov    %esp,%ebp
  101473:	56                   	push   %esi
  101474:	53                   	push   %ebx
  101475:	83 ec 10             	sub    $0x10,%esp
  101478:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
  10147b:	8b 43 04             	mov    0x4(%ebx),%eax
  10147e:	c1 e8 03             	shr    $0x3,%eax
  101481:	83 c0 02             	add    $0x2,%eax
  101484:	89 44 24 04          	mov    %eax,0x4(%esp)
  101488:	8b 03                	mov    (%ebx),%eax
  10148a:	89 04 24             	mov    %eax,(%esp)
  10148d:	e8 8e ec ff ff       	call   100120 <bread>
  dip = (struct dinode*)bp->data + ip->inum%IPB;
  dip->type = ip->type;
  101492:	0f b7 53 10          	movzwl 0x10(%ebx),%edx
iupdate(struct inode *ip)
{
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
  101496:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
  101498:	8b 43 04             	mov    0x4(%ebx),%eax
  10149b:	83 e0 07             	and    $0x7,%eax
  10149e:	c1 e0 06             	shl    $0x6,%eax
  1014a1:	8d 44 06 18          	lea    0x18(%esi,%eax,1),%eax
  dip->type = ip->type;
  1014a5:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
  1014a8:	0f b7 53 12          	movzwl 0x12(%ebx),%edx
  1014ac:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
  1014b0:	0f b7 53 14          	movzwl 0x14(%ebx),%edx
  1014b4:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
  1014b8:	0f b7 53 16          	movzwl 0x16(%ebx),%edx
  1014bc:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
  1014c0:	8b 53 18             	mov    0x18(%ebx),%edx
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
  1014c3:	83 c3 1c             	add    $0x1c,%ebx
  dip = (struct dinode*)bp->data + ip->inum%IPB;
  dip->type = ip->type;
  dip->major = ip->major;
  dip->minor = ip->minor;
  dip->nlink = ip->nlink;
  dip->size = ip->size;
  1014c6:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
  1014c9:	83 c0 0c             	add    $0xc,%eax
  1014cc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  1014d0:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
  1014d7:	00 
  1014d8:	89 04 24             	mov    %eax,(%esp)
  1014db:	e8 c0 28 00 00       	call   103da0 <memmove>
  bwrite(bp);
  1014e0:	89 34 24             	mov    %esi,(%esp)
  1014e3:	e8 08 ec ff ff       	call   1000f0 <bwrite>
  brelse(bp);
  1014e8:	89 75 08             	mov    %esi,0x8(%ebp)
}
  1014eb:	83 c4 10             	add    $0x10,%esp
  1014ee:	5b                   	pop    %ebx
  1014ef:	5e                   	pop    %esi
  1014f0:	5d                   	pop    %ebp
  dip->minor = ip->minor;
  dip->nlink = ip->nlink;
  dip->size = ip->size;
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
  bwrite(bp);
  brelse(bp);
  1014f1:	e9 7a eb ff ff       	jmp    100070 <brelse>
  1014f6:	8d 76 00             	lea    0x0(%esi),%esi
  1014f9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101500 <writei>:
}

// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
  101500:	55                   	push   %ebp
  101501:	89 e5                	mov    %esp,%ebp
  101503:	83 ec 38             	sub    $0x38,%esp
  101506:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  101509:	8b 5d 08             	mov    0x8(%ebp),%ebx
  10150c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  10150f:	8b 4d 14             	mov    0x14(%ebp),%ecx
  101512:	89 7d fc             	mov    %edi,-0x4(%ebp)
  101515:	8b 75 10             	mov    0x10(%ebp),%esi
  101518:	8b 7d 0c             	mov    0xc(%ebp),%edi
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
  10151b:	66 83 7b 10 03       	cmpw   $0x3,0x10(%ebx)
  101520:	74 1e                	je     101540 <writei+0x40>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
      return -1;
    return devsw[ip->major].write(ip, src, n);
  }

  if(off > ip->size || off + n < off)
  101522:	39 73 18             	cmp    %esi,0x18(%ebx)
  101525:	73 41                	jae    101568 <writei+0x68>

  if(n > 0 && off > ip->size){
    ip->size = off;
    iupdate(ip);
  }
  return n;
  101527:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  10152c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10152f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  101532:	8b 7d fc             	mov    -0x4(%ebp),%edi
  101535:	89 ec                	mov    %ebp,%esp
  101537:	5d                   	pop    %ebp
  101538:	c3                   	ret    
  101539:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
{
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
  101540:	0f b7 43 12          	movzwl 0x12(%ebx),%eax
  101544:	66 83 f8 09          	cmp    $0x9,%ax
  101548:	77 dd                	ja     101527 <writei+0x27>
  10154a:	98                   	cwtl   
  10154b:	8b 04 c5 84 aa 10 00 	mov    0x10aa84(,%eax,8),%eax
  101552:	85 c0                	test   %eax,%eax
  101554:	74 d1                	je     101527 <writei+0x27>
      return -1;
    return devsw[ip->major].write(ip, src, n);
  101556:	89 4d 10             	mov    %ecx,0x10(%ebp)
  if(n > 0 && off > ip->size){
    ip->size = off;
    iupdate(ip);
  }
  return n;
}
  101559:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10155c:	8b 75 f8             	mov    -0x8(%ebp),%esi
  10155f:	8b 7d fc             	mov    -0x4(%ebp),%edi
  101562:	89 ec                	mov    %ebp,%esp
  101564:	5d                   	pop    %ebp
  struct buf *bp;

  if(ip->type == T_DEV){
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
      return -1;
    return devsw[ip->major].write(ip, src, n);
  101565:	ff e0                	jmp    *%eax
  101567:	90                   	nop
  }

  if(off > ip->size || off + n < off)
  101568:	89 c8                	mov    %ecx,%eax
  10156a:	01 f0                	add    %esi,%eax
  10156c:	72 b9                	jb     101527 <writei+0x27>
    return -1;
  if(off + n > MAXFILE*BSIZE)
  10156e:	3d 00 18 01 00       	cmp    $0x11800,%eax
  101573:	76 07                	jbe    10157c <writei+0x7c>
    n = MAXFILE*BSIZE - off;
  101575:	b9 00 18 01 00       	mov    $0x11800,%ecx
  10157a:	29 f1                	sub    %esi,%ecx

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
  10157c:	85 c9                	test   %ecx,%ecx
  10157e:	0f 84 91 00 00 00    	je     101615 <writei+0x115>
  101584:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
  10158b:	89 7d e0             	mov    %edi,-0x20(%ebp)
  10158e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  101591:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    return -1;
  if(off + n > MAXFILE*BSIZE)
    n = MAXFILE*BSIZE - off;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  101598:	89 f2                	mov    %esi,%edx
  10159a:	89 d8                	mov    %ebx,%eax
  10159c:	c1 ea 09             	shr    $0x9,%edx
    m = min(n - tot, BSIZE - off%BSIZE);
  10159f:	bf 00 02 00 00       	mov    $0x200,%edi
    return -1;
  if(off + n > MAXFILE*BSIZE)
    n = MAXFILE*BSIZE - off;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  1015a4:	e8 07 fd ff ff       	call   1012b0 <bmap>
  1015a9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1015ad:	8b 03                	mov    (%ebx),%eax
  1015af:	89 04 24             	mov    %eax,(%esp)
  1015b2:	e8 69 eb ff ff       	call   100120 <bread>
    m = min(n - tot, BSIZE - off%BSIZE);
  1015b7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1015ba:	2b 4d e4             	sub    -0x1c(%ebp),%ecx
    return -1;
  if(off + n > MAXFILE*BSIZE)
    n = MAXFILE*BSIZE - off;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
  1015bd:	89 c2                	mov    %eax,%edx
    m = min(n - tot, BSIZE - off%BSIZE);
  1015bf:	89 f0                	mov    %esi,%eax
  1015c1:	25 ff 01 00 00       	and    $0x1ff,%eax
  1015c6:	29 c7                	sub    %eax,%edi
  1015c8:	39 cf                	cmp    %ecx,%edi
  1015ca:	0f 47 f9             	cmova  %ecx,%edi
    memmove(bp->data + off%BSIZE, src, m);
  1015cd:	89 7c 24 08          	mov    %edi,0x8(%esp)
  1015d1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  1015d4:	8d 44 02 18          	lea    0x18(%edx,%eax,1),%eax
  1015d8:	89 04 24             	mov    %eax,(%esp)
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    n = MAXFILE*BSIZE - off;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
  1015db:	01 fe                	add    %edi,%esi
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(bp->data + off%BSIZE, src, m);
  1015dd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  1015e1:	89 55 d8             	mov    %edx,-0x28(%ebp)
  1015e4:	e8 b7 27 00 00       	call   103da0 <memmove>
    bwrite(bp);
  1015e9:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1015ec:	89 14 24             	mov    %edx,(%esp)
  1015ef:	e8 fc ea ff ff       	call   1000f0 <bwrite>
    brelse(bp);
  1015f4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1015f7:	89 14 24             	mov    %edx,(%esp)
  1015fa:	e8 71 ea ff ff       	call   100070 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    n = MAXFILE*BSIZE - off;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
  1015ff:	01 7d e4             	add    %edi,-0x1c(%ebp)
  101602:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101605:	01 7d e0             	add    %edi,-0x20(%ebp)
  101608:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  10160b:	77 8b                	ja     101598 <writei+0x98>
    memmove(bp->data + off%BSIZE, src, m);
    bwrite(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
  10160d:	3b 73 18             	cmp    0x18(%ebx),%esi
  101610:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  101613:	77 07                	ja     10161c <writei+0x11c>
    ip->size = off;
    iupdate(ip);
  }
  return n;
  101615:	89 c8                	mov    %ecx,%eax
  101617:	e9 10 ff ff ff       	jmp    10152c <writei+0x2c>
    bwrite(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
    ip->size = off;
  10161c:	89 73 18             	mov    %esi,0x18(%ebx)
    iupdate(ip);
  10161f:	89 1c 24             	mov    %ebx,(%esp)
  101622:	89 4d d8             	mov    %ecx,-0x28(%ebp)
  101625:	e8 46 fe ff ff       	call   101470 <iupdate>
  10162a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  }
  return n;
  10162d:	89 c8                	mov    %ecx,%eax
  10162f:	e9 f8 fe ff ff       	jmp    10152c <writei+0x2c>
  101634:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  10163a:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00101640 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
  101640:	55                   	push   %ebp
  101641:	89 e5                	mov    %esp,%ebp
  101643:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
  101646:	8b 45 0c             	mov    0xc(%ebp),%eax
  101649:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
  101650:	00 
  101651:	89 44 24 04          	mov    %eax,0x4(%esp)
  101655:	8b 45 08             	mov    0x8(%ebp),%eax
  101658:	89 04 24             	mov    %eax,(%esp)
  10165b:	e8 b0 27 00 00       	call   103e10 <strncmp>
}
  101660:	c9                   	leave  
  101661:	c3                   	ret    
  101662:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  101669:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101670 <dirlookup>:
// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
// Caller must have already locked dp.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
  101670:	55                   	push   %ebp
  101671:	89 e5                	mov    %esp,%ebp
  101673:	57                   	push   %edi
  101674:	56                   	push   %esi
  101675:	53                   	push   %ebx
  101676:	83 ec 3c             	sub    $0x3c,%esp
  101679:	8b 45 08             	mov    0x8(%ebp),%eax
  10167c:	8b 55 10             	mov    0x10(%ebp),%edx
  10167f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  101682:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101685:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  uint off, inum;
  struct buf *bp;
  struct dirent *de;

  if(dp->type != T_DIR)
  101688:	66 83 78 10 01       	cmpw   $0x1,0x10(%eax)
  10168d:	0f 85 d0 00 00 00    	jne    101763 <dirlookup+0xf3>
    panic("dirlookup not DIR");
  101693:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

  for(off = 0; off < dp->size; off += BSIZE){
  10169a:	8b 48 18             	mov    0x18(%eax),%ecx
  10169d:	85 c9                	test   %ecx,%ecx
  10169f:	0f 84 b4 00 00 00    	je     101759 <dirlookup+0xe9>
    bp = bread(dp->dev, bmap(dp, off / BSIZE));
  1016a5:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1016a8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1016ab:	c1 ea 09             	shr    $0x9,%edx
  1016ae:	e8 fd fb ff ff       	call   1012b0 <bmap>
  1016b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016b7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1016ba:	8b 01                	mov    (%ecx),%eax
  1016bc:	89 04 24             	mov    %eax,(%esp)
  1016bf:	e8 5c ea ff ff       	call   100120 <bread>
  1016c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
// Caller must have already locked dp.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
  1016c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += BSIZE){
    bp = bread(dp->dev, bmap(dp, off / BSIZE));
    for(de = (struct dirent*)bp->data;
  1016ca:	83 c0 18             	add    $0x18,%eax
  1016cd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  1016d0:	89 c6                	mov    %eax,%esi

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
// Caller must have already locked dp.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
  1016d2:	81 c7 18 02 00 00    	add    $0x218,%edi
  1016d8:	eb 0d                	jmp    1016e7 <dirlookup+0x77>
  1016da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

  for(off = 0; off < dp->size; off += BSIZE){
    bp = bread(dp->dev, bmap(dp, off / BSIZE));
    for(de = (struct dirent*)bp->data;
        de < (struct dirent*)(bp->data + BSIZE);
        de++){
  1016e0:	83 c6 10             	add    $0x10,%esi
  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += BSIZE){
    bp = bread(dp->dev, bmap(dp, off / BSIZE));
    for(de = (struct dirent*)bp->data;
  1016e3:	39 fe                	cmp    %edi,%esi
  1016e5:	74 51                	je     101738 <dirlookup+0xc8>
        de < (struct dirent*)(bp->data + BSIZE);
        de++){
      if(de->inum == 0)
  1016e7:	66 83 3e 00          	cmpw   $0x0,(%esi)
  1016eb:	74 f3                	je     1016e0 <dirlookup+0x70>
        continue;
      if(namecmp(name, de->name) == 0){
  1016ed:	8d 46 02             	lea    0x2(%esi),%eax
  1016f0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016f4:	89 1c 24             	mov    %ebx,(%esp)
  1016f7:	e8 44 ff ff ff       	call   101640 <namecmp>
  1016fc:	85 c0                	test   %eax,%eax
  1016fe:	75 e0                	jne    1016e0 <dirlookup+0x70>
        // entry matches path element
        if(poff)
  101700:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101703:	85 d2                	test   %edx,%edx
  101705:	74 0e                	je     101715 <dirlookup+0xa5>
          *poff = off + (uchar*)de - bp->data;
  101707:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10170a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10170d:	8d 04 06             	lea    (%esi,%eax,1),%eax
  101710:	2b 45 d8             	sub    -0x28(%ebp),%eax
  101713:	89 02                	mov    %eax,(%edx)
        inum = de->inum;
        brelse(bp);
  101715:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
        continue;
      if(namecmp(name, de->name) == 0){
        // entry matches path element
        if(poff)
          *poff = off + (uchar*)de - bp->data;
        inum = de->inum;
  101718:	0f b7 1e             	movzwl (%esi),%ebx
        brelse(bp);
  10171b:	89 0c 24             	mov    %ecx,(%esp)
  10171e:	e8 4d e9 ff ff       	call   100070 <brelse>
        return iget(dp->dev, inum);
  101723:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  101726:	89 da                	mov    %ebx,%edx
  101728:	8b 01                	mov    (%ecx),%eax
      }
    }
    brelse(bp);
  }
  return 0;
}
  10172a:	83 c4 3c             	add    $0x3c,%esp
  10172d:	5b                   	pop    %ebx
  10172e:	5e                   	pop    %esi
  10172f:	5f                   	pop    %edi
  101730:	5d                   	pop    %ebp
        // entry matches path element
        if(poff)
          *poff = off + (uchar*)de - bp->data;
        inum = de->inum;
        brelse(bp);
        return iget(dp->dev, inum);
  101731:	e9 9a f9 ff ff       	jmp    1010d0 <iget>
  101736:	66 90                	xchg   %ax,%ax
      }
    }
    brelse(bp);
  101738:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10173b:	89 04 24             	mov    %eax,(%esp)
  10173e:	e8 2d e9 ff ff       	call   100070 <brelse>
  struct dirent *de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += BSIZE){
  101743:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101746:	81 45 e0 00 02 00 00 	addl   $0x200,-0x20(%ebp)
  10174d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  101750:	39 4a 18             	cmp    %ecx,0x18(%edx)
  101753:	0f 87 4c ff ff ff    	ja     1016a5 <dirlookup+0x35>
      }
    }
    brelse(bp);
  }
  return 0;
}
  101759:	83 c4 3c             	add    $0x3c,%esp
  10175c:	31 c0                	xor    %eax,%eax
  10175e:	5b                   	pop    %ebx
  10175f:	5e                   	pop    %esi
  101760:	5f                   	pop    %edi
  101761:	5d                   	pop    %ebp
  101762:	c3                   	ret    
  uint off, inum;
  struct buf *bp;
  struct dirent *de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");
  101763:	c7 04 24 a4 66 10 00 	movl   $0x1066a4,(%esp)
  10176a:	e8 b1 f1 ff ff       	call   100920 <panic>
  10176f:	90                   	nop

00101770 <iunlock>:
}

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
  101770:	55                   	push   %ebp
  101771:	89 e5                	mov    %esp,%ebp
  101773:	53                   	push   %ebx
  101774:	83 ec 14             	sub    $0x14,%esp
  101777:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
  10177a:	85 db                	test   %ebx,%ebx
  10177c:	74 36                	je     1017b4 <iunlock+0x44>
  10177e:	f6 43 0c 01          	testb  $0x1,0xc(%ebx)
  101782:	74 30                	je     1017b4 <iunlock+0x44>
  101784:	8b 43 08             	mov    0x8(%ebx),%eax
  101787:	85 c0                	test   %eax,%eax
  101789:	7e 29                	jle    1017b4 <iunlock+0x44>
    panic("iunlock");

  acquire(&icache.lock);
  10178b:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101792:	e8 e9 24 00 00       	call   103c80 <acquire>
  ip->flags &= ~I_BUSY;
  101797:	83 63 0c fe          	andl   $0xfffffffe,0xc(%ebx)
  wakeup(ip);
  10179b:	89 1c 24             	mov    %ebx,(%esp)
  10179e:	e8 8d 19 00 00       	call   103130 <wakeup>
  release(&icache.lock);
  1017a3:	c7 45 08 e0 aa 10 00 	movl   $0x10aae0,0x8(%ebp)
}
  1017aa:	83 c4 14             	add    $0x14,%esp
  1017ad:	5b                   	pop    %ebx
  1017ae:	5d                   	pop    %ebp
    panic("iunlock");

  acquire(&icache.lock);
  ip->flags &= ~I_BUSY;
  wakeup(ip);
  release(&icache.lock);
  1017af:	e9 7c 24 00 00       	jmp    103c30 <release>
// Unlock the given inode.
void
iunlock(struct inode *ip)
{
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
    panic("iunlock");
  1017b4:	c7 04 24 b6 66 10 00 	movl   $0x1066b6,(%esp)
  1017bb:	e8 60 f1 ff ff       	call   100920 <panic>

001017c0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
  1017c0:	55                   	push   %ebp
  1017c1:	89 e5                	mov    %esp,%ebp
  1017c3:	57                   	push   %edi
  1017c4:	56                   	push   %esi
  1017c5:	89 c6                	mov    %eax,%esi
  1017c7:	53                   	push   %ebx
  1017c8:	89 d3                	mov    %edx,%ebx
  1017ca:	83 ec 2c             	sub    $0x2c,%esp
static void
bzero(int dev, int bno)
{
  struct buf *bp;
  
  bp = bread(dev, bno);
  1017cd:	89 54 24 04          	mov    %edx,0x4(%esp)
  1017d1:	89 04 24             	mov    %eax,(%esp)
  1017d4:	e8 47 e9 ff ff       	call   100120 <bread>
  memset(bp->data, 0, BSIZE);
  1017d9:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
  1017e0:	00 
  1017e1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1017e8:	00 
static void
bzero(int dev, int bno)
{
  struct buf *bp;
  
  bp = bread(dev, bno);
  1017e9:	89 c7                	mov    %eax,%edi
  memset(bp->data, 0, BSIZE);
  1017eb:	83 c0 18             	add    $0x18,%eax
  1017ee:	89 04 24             	mov    %eax,(%esp)
  1017f1:	e8 2a 25 00 00       	call   103d20 <memset>
  bwrite(bp);
  1017f6:	89 3c 24             	mov    %edi,(%esp)
  1017f9:	e8 f2 e8 ff ff       	call   1000f0 <bwrite>
  brelse(bp);
  1017fe:	89 3c 24             	mov    %edi,(%esp)
  101801:	e8 6a e8 ff ff       	call   100070 <brelse>
  struct superblock sb;
  int bi, m;

  bzero(dev, b);

  readsb(dev, &sb);
  101806:	89 f0                	mov    %esi,%eax
  101808:	8d 55 dc             	lea    -0x24(%ebp),%edx
  10180b:	e8 80 f9 ff ff       	call   101190 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  101810:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101813:	89 da                	mov    %ebx,%edx
  101815:	c1 ea 0c             	shr    $0xc,%edx
  101818:	89 34 24             	mov    %esi,(%esp)
  bi = b % BPB;
  m = 1 << (bi % 8);
  10181b:	be 01 00 00 00       	mov    $0x1,%esi
  int bi, m;

  bzero(dev, b);

  readsb(dev, &sb);
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  101820:	c1 e8 03             	shr    $0x3,%eax
  101823:	8d 44 10 03          	lea    0x3(%eax,%edx,1),%eax
  101827:	89 44 24 04          	mov    %eax,0x4(%esp)
  10182b:	e8 f0 e8 ff ff       	call   100120 <bread>
  bi = b % BPB;
  101830:	89 da                	mov    %ebx,%edx
  m = 1 << (bi % 8);
  101832:	89 d9                	mov    %ebx,%ecx

  bzero(dev, b);

  readsb(dev, &sb);
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  bi = b % BPB;
  101834:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
  m = 1 << (bi % 8);
  10183a:	83 e1 07             	and    $0x7,%ecx
  if((bp->data[bi/8] & m) == 0)
  10183d:	c1 fa 03             	sar    $0x3,%edx
  bzero(dev, b);

  readsb(dev, &sb);
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  bi = b % BPB;
  m = 1 << (bi % 8);
  101840:	d3 e6                	shl    %cl,%esi
  if((bp->data[bi/8] & m) == 0)
  101842:	0f b6 4c 10 18       	movzbl 0x18(%eax,%edx,1),%ecx
  int bi, m;

  bzero(dev, b);

  readsb(dev, &sb);
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  101847:	89 c7                	mov    %eax,%edi
  bi = b % BPB;
  m = 1 << (bi % 8);
  if((bp->data[bi/8] & m) == 0)
  101849:	0f b6 c1             	movzbl %cl,%eax
  10184c:	85 f0                	test   %esi,%eax
  10184e:	74 22                	je     101872 <bfree+0xb2>
    panic("freeing free block");
  bp->data[bi/8] &= ~m;  // Mark block free on disk.
  101850:	89 f0                	mov    %esi,%eax
  101852:	f7 d0                	not    %eax
  101854:	21 c8                	and    %ecx,%eax
  101856:	88 44 17 18          	mov    %al,0x18(%edi,%edx,1)
  bwrite(bp);
  10185a:	89 3c 24             	mov    %edi,(%esp)
  10185d:	e8 8e e8 ff ff       	call   1000f0 <bwrite>
  brelse(bp);
  101862:	89 3c 24             	mov    %edi,(%esp)
  101865:	e8 06 e8 ff ff       	call   100070 <brelse>
}
  10186a:	83 c4 2c             	add    $0x2c,%esp
  10186d:	5b                   	pop    %ebx
  10186e:	5e                   	pop    %esi
  10186f:	5f                   	pop    %edi
  101870:	5d                   	pop    %ebp
  101871:	c3                   	ret    
  readsb(dev, &sb);
  bp = bread(dev, BBLOCK(b, sb.ninodes));
  bi = b % BPB;
  m = 1 << (bi % 8);
  if((bp->data[bi/8] & m) == 0)
    panic("freeing free block");
  101872:	c7 04 24 be 66 10 00 	movl   $0x1066be,(%esp)
  101879:	e8 a2 f0 ff ff       	call   100920 <panic>
  10187e:	66 90                	xchg   %ax,%ax

00101880 <iput>:
}

// Caller holds reference to unlocked ip.  Drop reference.
void
iput(struct inode *ip)
{
  101880:	55                   	push   %ebp
  101881:	89 e5                	mov    %esp,%ebp
  101883:	57                   	push   %edi
  101884:	56                   	push   %esi
  101885:	53                   	push   %ebx
  101886:	83 ec 2c             	sub    $0x2c,%esp
  101889:	8b 75 08             	mov    0x8(%ebp),%esi
  acquire(&icache.lock);
  10188c:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101893:	e8 e8 23 00 00       	call   103c80 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
  101898:	8b 46 08             	mov    0x8(%esi),%eax
  10189b:	83 f8 01             	cmp    $0x1,%eax
  10189e:	0f 85 a1 00 00 00    	jne    101945 <iput+0xc5>
  1018a4:	8b 56 0c             	mov    0xc(%esi),%edx
  1018a7:	f6 c2 02             	test   $0x2,%dl
  1018aa:	0f 84 95 00 00 00    	je     101945 <iput+0xc5>
  1018b0:	66 83 7e 16 00       	cmpw   $0x0,0x16(%esi)
  1018b5:	0f 85 8a 00 00 00    	jne    101945 <iput+0xc5>
    // inode is no longer used: truncate and free inode.
    if(ip->flags & I_BUSY)
  1018bb:	f6 c2 01             	test   $0x1,%dl
  1018be:	66 90                	xchg   %ax,%ax
  1018c0:	0f 85 f8 00 00 00    	jne    1019be <iput+0x13e>
      panic("iput busy");
    ip->flags |= I_BUSY;
  1018c6:	83 ca 01             	or     $0x1,%edx
    release(&icache.lock);
  1018c9:	89 f3                	mov    %esi,%ebx
  acquire(&icache.lock);
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
    // inode is no longer used: truncate and free inode.
    if(ip->flags & I_BUSY)
      panic("iput busy");
    ip->flags |= I_BUSY;
  1018cb:	89 56 0c             	mov    %edx,0xc(%esi)
  release(&icache.lock);
}

// Caller holds reference to unlocked ip.  Drop reference.
void
iput(struct inode *ip)
  1018ce:	8d 7e 30             	lea    0x30(%esi),%edi
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
    // inode is no longer used: truncate and free inode.
    if(ip->flags & I_BUSY)
      panic("iput busy");
    ip->flags |= I_BUSY;
    release(&icache.lock);
  1018d1:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  1018d8:	e8 53 23 00 00       	call   103c30 <release>
  1018dd:	eb 08                	jmp    1018e7 <iput+0x67>
  1018df:	90                   	nop
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
  1018e0:	83 c3 04             	add    $0x4,%ebx
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
  1018e3:	39 fb                	cmp    %edi,%ebx
  1018e5:	74 1c                	je     101903 <iput+0x83>
    if(ip->addrs[i]){
  1018e7:	8b 53 1c             	mov    0x1c(%ebx),%edx
  1018ea:	85 d2                	test   %edx,%edx
  1018ec:	74 f2                	je     1018e0 <iput+0x60>
      bfree(ip->dev, ip->addrs[i]);
  1018ee:	8b 06                	mov    (%esi),%eax
  1018f0:	e8 cb fe ff ff       	call   1017c0 <bfree>
      ip->addrs[i] = 0;
  1018f5:	c7 43 1c 00 00 00 00 	movl   $0x0,0x1c(%ebx)
  1018fc:	83 c3 04             	add    $0x4,%ebx
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
  1018ff:	39 fb                	cmp    %edi,%ebx
  101901:	75 e4                	jne    1018e7 <iput+0x67>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
  101903:	8b 46 4c             	mov    0x4c(%esi),%eax
  101906:	85 c0                	test   %eax,%eax
  101908:	75 56                	jne    101960 <iput+0xe0>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
  10190a:	c7 46 18 00 00 00 00 	movl   $0x0,0x18(%esi)
  iupdate(ip);
  101911:	89 34 24             	mov    %esi,(%esp)
  101914:	e8 57 fb ff ff       	call   101470 <iupdate>
    if(ip->flags & I_BUSY)
      panic("iput busy");
    ip->flags |= I_BUSY;
    release(&icache.lock);
    itrunc(ip);
    ip->type = 0;
  101919:	66 c7 46 10 00 00    	movw   $0x0,0x10(%esi)
    iupdate(ip);
  10191f:	89 34 24             	mov    %esi,(%esp)
  101922:	e8 49 fb ff ff       	call   101470 <iupdate>
    acquire(&icache.lock);
  101927:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  10192e:	e8 4d 23 00 00       	call   103c80 <acquire>
    ip->flags = 0;
  101933:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
    wakeup(ip);
  10193a:	89 34 24             	mov    %esi,(%esp)
  10193d:	e8 ee 17 00 00       	call   103130 <wakeup>
  101942:	8b 46 08             	mov    0x8(%esi),%eax
  }
  ip->ref--;
  101945:	83 e8 01             	sub    $0x1,%eax
  101948:	89 46 08             	mov    %eax,0x8(%esi)
  release(&icache.lock);
  10194b:	c7 45 08 e0 aa 10 00 	movl   $0x10aae0,0x8(%ebp)
}
  101952:	83 c4 2c             	add    $0x2c,%esp
  101955:	5b                   	pop    %ebx
  101956:	5e                   	pop    %esi
  101957:	5f                   	pop    %edi
  101958:	5d                   	pop    %ebp
    acquire(&icache.lock);
    ip->flags = 0;
    wakeup(ip);
  }
  ip->ref--;
  release(&icache.lock);
  101959:	e9 d2 22 00 00       	jmp    103c30 <release>
  10195e:	66 90                	xchg   %ax,%ax
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
  101960:	89 44 24 04          	mov    %eax,0x4(%esp)
  101964:	8b 06                	mov    (%esi),%eax
    a = (uint*)bp->data;
  101966:	31 db                	xor    %ebx,%ebx
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
  101968:	89 04 24             	mov    %eax,(%esp)
  10196b:	e8 b0 e7 ff ff       	call   100120 <bread>
    a = (uint*)bp->data;
  101970:	89 c7                	mov    %eax,%edi
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
  101972:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
  101975:	83 c7 18             	add    $0x18,%edi
  101978:	31 c0                	xor    %eax,%eax
  10197a:	eb 11                	jmp    10198d <iput+0x10d>
  10197c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    for(j = 0; j < NINDIRECT; j++){
  101980:	83 c3 01             	add    $0x1,%ebx
  101983:	81 fb 80 00 00 00    	cmp    $0x80,%ebx
  101989:	89 d8                	mov    %ebx,%eax
  10198b:	74 10                	je     10199d <iput+0x11d>
      if(a[j])
  10198d:	8b 14 87             	mov    (%edi,%eax,4),%edx
  101990:	85 d2                	test   %edx,%edx
  101992:	74 ec                	je     101980 <iput+0x100>
        bfree(ip->dev, a[j]);
  101994:	8b 06                	mov    (%esi),%eax
  101996:	e8 25 fe ff ff       	call   1017c0 <bfree>
  10199b:	eb e3                	jmp    101980 <iput+0x100>
    }
    brelse(bp);
  10199d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1019a0:	89 04 24             	mov    %eax,(%esp)
  1019a3:	e8 c8 e6 ff ff       	call   100070 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
  1019a8:	8b 56 4c             	mov    0x4c(%esi),%edx
  1019ab:	8b 06                	mov    (%esi),%eax
  1019ad:	e8 0e fe ff ff       	call   1017c0 <bfree>
    ip->addrs[NDIRECT] = 0;
  1019b2:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  1019b9:	e9 4c ff ff ff       	jmp    10190a <iput+0x8a>
{
  acquire(&icache.lock);
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
    // inode is no longer used: truncate and free inode.
    if(ip->flags & I_BUSY)
      panic("iput busy");
  1019be:	c7 04 24 d1 66 10 00 	movl   $0x1066d1,(%esp)
  1019c5:	e8 56 ef ff ff       	call   100920 <panic>
  1019ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

001019d0 <dirlink>:
}

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
  1019d0:	55                   	push   %ebp
  1019d1:	89 e5                	mov    %esp,%ebp
  1019d3:	57                   	push   %edi
  1019d4:	56                   	push   %esi
  1019d5:	53                   	push   %ebx
  1019d6:	83 ec 2c             	sub    $0x2c,%esp
  1019d9:	8b 75 08             	mov    0x8(%ebp),%esi
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
  1019dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1019df:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1019e6:	00 
  1019e7:	89 34 24             	mov    %esi,(%esp)
  1019ea:	89 44 24 04          	mov    %eax,0x4(%esp)
  1019ee:	e8 7d fc ff ff       	call   101670 <dirlookup>
  1019f3:	85 c0                	test   %eax,%eax
  1019f5:	0f 85 89 00 00 00    	jne    101a84 <dirlink+0xb4>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
  1019fb:	8b 56 18             	mov    0x18(%esi),%edx
  1019fe:	85 d2                	test   %edx,%edx
  101a00:	0f 84 8d 00 00 00    	je     101a93 <dirlink+0xc3>
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
    iput(ip);
    return -1;
  101a06:	8d 7d d8             	lea    -0x28(%ebp),%edi
  101a09:	31 db                	xor    %ebx,%ebx
  101a0b:	eb 0b                	jmp    101a18 <dirlink+0x48>
  101a0d:	8d 76 00             	lea    0x0(%esi),%esi
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
  101a10:	83 c3 10             	add    $0x10,%ebx
  101a13:	39 5e 18             	cmp    %ebx,0x18(%esi)
  101a16:	76 24                	jbe    101a3c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
  101a18:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  101a1f:	00 
  101a20:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  101a24:	89 7c 24 04          	mov    %edi,0x4(%esp)
  101a28:	89 34 24             	mov    %esi,(%esp)
  101a2b:	e8 30 f9 ff ff       	call   101360 <readi>
  101a30:	83 f8 10             	cmp    $0x10,%eax
  101a33:	75 65                	jne    101a9a <dirlink+0xca>
      panic("dirlink read");
    if(de.inum == 0)
  101a35:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
  101a3a:	75 d4                	jne    101a10 <dirlink+0x40>
      break;
  }

  strncpy(de.name, name, DIRSIZ);
  101a3c:	8b 45 0c             	mov    0xc(%ebp),%eax
  101a3f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
  101a46:	00 
  101a47:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a4b:	8d 45 da             	lea    -0x26(%ebp),%eax
  101a4e:	89 04 24             	mov    %eax,(%esp)
  101a51:	e8 1a 24 00 00       	call   103e70 <strncpy>
  de.inum = inum;
  101a56:	8b 45 10             	mov    0x10(%ebp),%eax
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
  101a59:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  101a60:	00 
  101a61:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  101a65:	89 7c 24 04          	mov    %edi,0x4(%esp)
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
  de.inum = inum;
  101a69:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
  101a6d:	89 34 24             	mov    %esi,(%esp)
  101a70:	e8 8b fa ff ff       	call   101500 <writei>
  101a75:	83 f8 10             	cmp    $0x10,%eax
  101a78:	75 2c                	jne    101aa6 <dirlink+0xd6>
    panic("dirlink");
  101a7a:	31 c0                	xor    %eax,%eax
  
  return 0;
}
  101a7c:	83 c4 2c             	add    $0x2c,%esp
  101a7f:	5b                   	pop    %ebx
  101a80:	5e                   	pop    %esi
  101a81:	5f                   	pop    %edi
  101a82:	5d                   	pop    %ebp
  101a83:	c3                   	ret    
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
    iput(ip);
  101a84:	89 04 24             	mov    %eax,(%esp)
  101a87:	e8 f4 fd ff ff       	call   101880 <iput>
  101a8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    return -1;
  101a91:	eb e9                	jmp    101a7c <dirlink+0xac>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
  101a93:	8d 7d d8             	lea    -0x28(%ebp),%edi
  101a96:	31 db                	xor    %ebx,%ebx
  101a98:	eb a2                	jmp    101a3c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
  101a9a:	c7 04 24 db 66 10 00 	movl   $0x1066db,(%esp)
  101aa1:	e8 7a ee ff ff       	call   100920 <panic>
  }

  strncpy(de.name, name, DIRSIZ);
  de.inum = inum;
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
    panic("dirlink");
  101aa6:	c7 04 24 82 6c 10 00 	movl   $0x106c82,(%esp)
  101aad:	e8 6e ee ff ff       	call   100920 <panic>
  101ab2:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  101ab9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101ac0 <iunlockput>:
}

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
  101ac0:	55                   	push   %ebp
  101ac1:	89 e5                	mov    %esp,%ebp
  101ac3:	53                   	push   %ebx
  101ac4:	83 ec 14             	sub    $0x14,%esp
  101ac7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
  101aca:	89 1c 24             	mov    %ebx,(%esp)
  101acd:	e8 9e fc ff ff       	call   101770 <iunlock>
  iput(ip);
  101ad2:	89 5d 08             	mov    %ebx,0x8(%ebp)
}
  101ad5:	83 c4 14             	add    $0x14,%esp
  101ad8:	5b                   	pop    %ebx
  101ad9:	5d                   	pop    %ebp
// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
  iunlock(ip);
  iput(ip);
  101ada:	e9 a1 fd ff ff       	jmp    101880 <iput>
  101adf:	90                   	nop

00101ae0 <ialloc>:
static struct inode* iget(uint dev, uint inum);

// Allocate a new inode with the given type on device dev.
struct inode*
ialloc(uint dev, short type)
{
  101ae0:	55                   	push   %ebp
  101ae1:	89 e5                	mov    %esp,%ebp
  101ae3:	57                   	push   %edi
  101ae4:	56                   	push   %esi
  101ae5:	53                   	push   %ebx
  101ae6:	83 ec 3c             	sub    $0x3c,%esp
  101ae9:	0f b7 45 0c          	movzwl 0xc(%ebp),%eax
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
  101aed:	8d 55 dc             	lea    -0x24(%ebp),%edx
static struct inode* iget(uint dev, uint inum);

// Allocate a new inode with the given type on device dev.
struct inode*
ialloc(uint dev, short type)
{
  101af0:	66 89 45 d6          	mov    %ax,-0x2a(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
  101af4:	8b 45 08             	mov    0x8(%ebp),%eax
  101af7:	e8 94 f6 ff ff       	call   101190 <readsb>
  for(inum = 1; inum < sb.ninodes; inum++){  // loop over inode blocks
  101afc:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
  101b00:	0f 86 96 00 00 00    	jbe    101b9c <ialloc+0xbc>
  101b06:	be 01 00 00 00       	mov    $0x1,%esi
  101b0b:	bb 01 00 00 00       	mov    $0x1,%ebx
  101b10:	eb 18                	jmp    101b2a <ialloc+0x4a>
  101b12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  101b18:	83 c3 01             	add    $0x1,%ebx
      dip->type = type;
      bwrite(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  101b1b:	89 3c 24             	mov    %edi,(%esp)
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
  for(inum = 1; inum < sb.ninodes; inum++){  // loop over inode blocks
  101b1e:	89 de                	mov    %ebx,%esi
      dip->type = type;
      bwrite(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  101b20:	e8 4b e5 ff ff       	call   100070 <brelse>
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
  for(inum = 1; inum < sb.ninodes; inum++){  // loop over inode blocks
  101b25:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
  101b28:	76 72                	jbe    101b9c <ialloc+0xbc>
    bp = bread(dev, IBLOCK(inum));
  101b2a:	89 f0                	mov    %esi,%eax
  101b2c:	c1 e8 03             	shr    $0x3,%eax
  101b2f:	83 c0 02             	add    $0x2,%eax
  101b32:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b36:	8b 45 08             	mov    0x8(%ebp),%eax
  101b39:	89 04 24             	mov    %eax,(%esp)
  101b3c:	e8 df e5 ff ff       	call   100120 <bread>
  101b41:	89 c7                	mov    %eax,%edi
    dip = (struct dinode*)bp->data + inum%IPB;
  101b43:	89 f0                	mov    %esi,%eax
  101b45:	83 e0 07             	and    $0x7,%eax
  101b48:	c1 e0 06             	shl    $0x6,%eax
  101b4b:	8d 54 07 18          	lea    0x18(%edi,%eax,1),%edx
    if(dip->type == 0){  // a free inode
  101b4f:	66 83 3a 00          	cmpw   $0x0,(%edx)
  101b53:	75 c3                	jne    101b18 <ialloc+0x38>
      memset(dip, 0, sizeof(*dip));
  101b55:	89 14 24             	mov    %edx,(%esp)
  101b58:	89 55 d0             	mov    %edx,-0x30(%ebp)
  101b5b:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
  101b62:	00 
  101b63:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101b6a:	00 
  101b6b:	e8 b0 21 00 00       	call   103d20 <memset>
      dip->type = type;
  101b70:	8b 55 d0             	mov    -0x30(%ebp),%edx
  101b73:	0f b7 45 d6          	movzwl -0x2a(%ebp),%eax
  101b77:	66 89 02             	mov    %ax,(%edx)
      bwrite(bp);   // mark it allocated on the disk
  101b7a:	89 3c 24             	mov    %edi,(%esp)
  101b7d:	e8 6e e5 ff ff       	call   1000f0 <bwrite>
      brelse(bp);
  101b82:	89 3c 24             	mov    %edi,(%esp)
  101b85:	e8 e6 e4 ff ff       	call   100070 <brelse>
      return iget(dev, inum);
  101b8a:	8b 45 08             	mov    0x8(%ebp),%eax
  101b8d:	89 f2                	mov    %esi,%edx
  101b8f:	e8 3c f5 ff ff       	call   1010d0 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
  101b94:	83 c4 3c             	add    $0x3c,%esp
  101b97:	5b                   	pop    %ebx
  101b98:	5e                   	pop    %esi
  101b99:	5f                   	pop    %edi
  101b9a:	5d                   	pop    %ebp
  101b9b:	c3                   	ret    
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
  101b9c:	c7 04 24 e8 66 10 00 	movl   $0x1066e8,(%esp)
  101ba3:	e8 78 ed ff ff       	call   100920 <panic>
  101ba8:	90                   	nop
  101ba9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00101bb0 <ilock>:
}

// Lock the given inode.
void
ilock(struct inode *ip)
{
  101bb0:	55                   	push   %ebp
  101bb1:	89 e5                	mov    %esp,%ebp
  101bb3:	56                   	push   %esi
  101bb4:	53                   	push   %ebx
  101bb5:	83 ec 10             	sub    $0x10,%esp
  101bb8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
  101bbb:	85 db                	test   %ebx,%ebx
  101bbd:	0f 84 e5 00 00 00    	je     101ca8 <ilock+0xf8>
  101bc3:	8b 4b 08             	mov    0x8(%ebx),%ecx
  101bc6:	85 c9                	test   %ecx,%ecx
  101bc8:	0f 8e da 00 00 00    	jle    101ca8 <ilock+0xf8>
    panic("ilock");

  acquire(&icache.lock);
  101bce:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101bd5:	e8 a6 20 00 00       	call   103c80 <acquire>
  while(ip->flags & I_BUSY)
  101bda:	8b 43 0c             	mov    0xc(%ebx),%eax
  101bdd:	a8 01                	test   $0x1,%al
  101bdf:	74 1e                	je     101bff <ilock+0x4f>
  101be1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    sleep(ip, &icache.lock);
  101be8:	c7 44 24 04 e0 aa 10 	movl   $0x10aae0,0x4(%esp)
  101bef:	00 
  101bf0:	89 1c 24             	mov    %ebx,(%esp)
  101bf3:	e8 58 16 00 00       	call   103250 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
  101bf8:	8b 43 0c             	mov    0xc(%ebx),%eax
  101bfb:	a8 01                	test   $0x1,%al
  101bfd:	75 e9                	jne    101be8 <ilock+0x38>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
  101bff:	83 c8 01             	or     $0x1,%eax
  101c02:	89 43 0c             	mov    %eax,0xc(%ebx)
  release(&icache.lock);
  101c05:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101c0c:	e8 1f 20 00 00       	call   103c30 <release>

  if(!(ip->flags & I_VALID)){
  101c11:	f6 43 0c 02          	testb  $0x2,0xc(%ebx)
  101c15:	74 09                	je     101c20 <ilock+0x70>
    brelse(bp);
    ip->flags |= I_VALID;
    if(ip->type == 0)
      panic("ilock: no type");
  }
}
  101c17:	83 c4 10             	add    $0x10,%esp
  101c1a:	5b                   	pop    %ebx
  101c1b:	5e                   	pop    %esi
  101c1c:	5d                   	pop    %ebp
  101c1d:	c3                   	ret    
  101c1e:	66 90                	xchg   %ax,%ax
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
  release(&icache.lock);

  if(!(ip->flags & I_VALID)){
    bp = bread(ip->dev, IBLOCK(ip->inum));
  101c20:	8b 43 04             	mov    0x4(%ebx),%eax
  101c23:	c1 e8 03             	shr    $0x3,%eax
  101c26:	83 c0 02             	add    $0x2,%eax
  101c29:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c2d:	8b 03                	mov    (%ebx),%eax
  101c2f:	89 04 24             	mov    %eax,(%esp)
  101c32:	e8 e9 e4 ff ff       	call   100120 <bread>
  101c37:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
  101c39:	8b 43 04             	mov    0x4(%ebx),%eax
  101c3c:	83 e0 07             	and    $0x7,%eax
  101c3f:	c1 e0 06             	shl    $0x6,%eax
  101c42:	8d 44 06 18          	lea    0x18(%esi,%eax,1),%eax
    ip->type = dip->type;
  101c46:	0f b7 10             	movzwl (%eax),%edx
  101c49:	66 89 53 10          	mov    %dx,0x10(%ebx)
    ip->major = dip->major;
  101c4d:	0f b7 50 02          	movzwl 0x2(%eax),%edx
  101c51:	66 89 53 12          	mov    %dx,0x12(%ebx)
    ip->minor = dip->minor;
  101c55:	0f b7 50 04          	movzwl 0x4(%eax),%edx
  101c59:	66 89 53 14          	mov    %dx,0x14(%ebx)
    ip->nlink = dip->nlink;
  101c5d:	0f b7 50 06          	movzwl 0x6(%eax),%edx
  101c61:	66 89 53 16          	mov    %dx,0x16(%ebx)
    ip->size = dip->size;
  101c65:	8b 50 08             	mov    0x8(%eax),%edx
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
  101c68:	83 c0 0c             	add    $0xc,%eax
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    ip->type = dip->type;
    ip->major = dip->major;
    ip->minor = dip->minor;
    ip->nlink = dip->nlink;
    ip->size = dip->size;
  101c6b:	89 53 18             	mov    %edx,0x18(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
  101c6e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c72:	8d 43 1c             	lea    0x1c(%ebx),%eax
  101c75:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
  101c7c:	00 
  101c7d:	89 04 24             	mov    %eax,(%esp)
  101c80:	e8 1b 21 00 00       	call   103da0 <memmove>
    brelse(bp);
  101c85:	89 34 24             	mov    %esi,(%esp)
  101c88:	e8 e3 e3 ff ff       	call   100070 <brelse>
    ip->flags |= I_VALID;
  101c8d:	83 4b 0c 02          	orl    $0x2,0xc(%ebx)
    if(ip->type == 0)
  101c91:	66 83 7b 10 00       	cmpw   $0x0,0x10(%ebx)
  101c96:	0f 85 7b ff ff ff    	jne    101c17 <ilock+0x67>
      panic("ilock: no type");
  101c9c:	c7 04 24 00 67 10 00 	movl   $0x106700,(%esp)
  101ca3:	e8 78 ec ff ff       	call   100920 <panic>
{
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
    panic("ilock");
  101ca8:	c7 04 24 fa 66 10 00 	movl   $0x1066fa,(%esp)
  101caf:	e8 6c ec ff ff       	call   100920 <panic>
  101cb4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  101cba:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00101cc0 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
  101cc0:	55                   	push   %ebp
  101cc1:	89 e5                	mov    %esp,%ebp
  101cc3:	57                   	push   %edi
  101cc4:	56                   	push   %esi
  101cc5:	53                   	push   %ebx
  101cc6:	89 c3                	mov    %eax,%ebx
  101cc8:	83 ec 2c             	sub    $0x2c,%esp
  101ccb:	89 55 e0             	mov    %edx,-0x20(%ebp)
  101cce:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
  101cd1:	80 38 2f             	cmpb   $0x2f,(%eax)
  101cd4:	0f 84 14 01 00 00    	je     101dee <namex+0x12e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
  101cda:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  101ce0:	8b 40 68             	mov    0x68(%eax),%eax
  101ce3:	89 04 24             	mov    %eax,(%esp)
  101ce6:	e8 b5 f3 ff ff       	call   1010a0 <idup>
  101ceb:	89 c7                	mov    %eax,%edi
  101ced:	eb 04                	jmp    101cf3 <namex+0x33>
  101cef:	90                   	nop
{
  char *s;
  int len;

  while(*path == '/')
    path++;
  101cf0:	83 c3 01             	add    $0x1,%ebx
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
  101cf3:	0f b6 03             	movzbl (%ebx),%eax
  101cf6:	3c 2f                	cmp    $0x2f,%al
  101cf8:	74 f6                	je     101cf0 <namex+0x30>
    path++;
  if(*path == 0)
  101cfa:	84 c0                	test   %al,%al
  101cfc:	75 1a                	jne    101d18 <namex+0x58>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
  101cfe:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  101d01:	85 db                	test   %ebx,%ebx
  101d03:	0f 85 0d 01 00 00    	jne    101e16 <namex+0x156>
    iput(ip);
    return 0;
  }
  return ip;
}
  101d09:	83 c4 2c             	add    $0x2c,%esp
  101d0c:	89 f8                	mov    %edi,%eax
  101d0e:	5b                   	pop    %ebx
  101d0f:	5e                   	pop    %esi
  101d10:	5f                   	pop    %edi
  101d11:	5d                   	pop    %ebp
  101d12:	c3                   	ret    
  101d13:	90                   	nop
  101d14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
  101d18:	3c 2f                	cmp    $0x2f,%al
  101d1a:	0f 84 94 00 00 00    	je     101db4 <namex+0xf4>
  101d20:	89 de                	mov    %ebx,%esi
  101d22:	eb 08                	jmp    101d2c <namex+0x6c>
  101d24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101d28:	3c 2f                	cmp    $0x2f,%al
  101d2a:	74 0a                	je     101d36 <namex+0x76>
    path++;
  101d2c:	83 c6 01             	add    $0x1,%esi
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
  101d2f:	0f b6 06             	movzbl (%esi),%eax
  101d32:	84 c0                	test   %al,%al
  101d34:	75 f2                	jne    101d28 <namex+0x68>
  101d36:	89 f2                	mov    %esi,%edx
  101d38:	29 da                	sub    %ebx,%edx
    path++;
  len = path - s;
  if(len >= DIRSIZ)
  101d3a:	83 fa 0d             	cmp    $0xd,%edx
  101d3d:	7e 79                	jle    101db8 <namex+0xf8>
    memmove(name, s, DIRSIZ);
  101d3f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
  101d46:	00 
  101d47:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  101d4b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101d4e:	89 04 24             	mov    %eax,(%esp)
  101d51:	e8 4a 20 00 00       	call   103da0 <memmove>
  101d56:	eb 03                	jmp    101d5b <namex+0x9b>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
    path++;
  101d58:	83 c6 01             	add    $0x1,%esi
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
  101d5b:	80 3e 2f             	cmpb   $0x2f,(%esi)
  101d5e:	74 f8                	je     101d58 <namex+0x98>
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
  101d60:	85 f6                	test   %esi,%esi
  101d62:	74 9a                	je     101cfe <namex+0x3e>
    ilock(ip);
  101d64:	89 3c 24             	mov    %edi,(%esp)
  101d67:	e8 44 fe ff ff       	call   101bb0 <ilock>
    if(ip->type != T_DIR){
  101d6c:	66 83 7f 10 01       	cmpw   $0x1,0x10(%edi)
  101d71:	75 67                	jne    101dda <namex+0x11a>
      iunlockput(ip);
      return 0;
    }
    if(nameiparent && *path == '\0'){
  101d73:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101d76:	85 c0                	test   %eax,%eax
  101d78:	74 0c                	je     101d86 <namex+0xc6>
  101d7a:	80 3e 00             	cmpb   $0x0,(%esi)
  101d7d:	8d 76 00             	lea    0x0(%esi),%esi
  101d80:	0f 84 7e 00 00 00    	je     101e04 <namex+0x144>
      // Stop one level early.
      iunlock(ip);
      return ip;
    }
    if((next = dirlookup(ip, name, 0)) == 0){
  101d86:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  101d8d:	00 
  101d8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101d91:	89 3c 24             	mov    %edi,(%esp)
  101d94:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d98:	e8 d3 f8 ff ff       	call   101670 <dirlookup>
  101d9d:	85 c0                	test   %eax,%eax
  101d9f:	89 c3                	mov    %eax,%ebx
  101da1:	74 37                	je     101dda <namex+0x11a>
      iunlockput(ip);
      return 0;
    }
    iunlockput(ip);
  101da3:	89 3c 24             	mov    %edi,(%esp)
  101da6:	89 df                	mov    %ebx,%edi
  101da8:	89 f3                	mov    %esi,%ebx
  101daa:	e8 11 fd ff ff       	call   101ac0 <iunlockput>
  101daf:	e9 3f ff ff ff       	jmp    101cf3 <namex+0x33>
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
  101db4:	89 de                	mov    %ebx,%esi
  101db6:	31 d2                	xor    %edx,%edx
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
  101db8:	89 54 24 08          	mov    %edx,0x8(%esp)
  101dbc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  101dc0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101dc3:	89 04 24             	mov    %eax,(%esp)
  101dc6:	89 55 dc             	mov    %edx,-0x24(%ebp)
  101dc9:	e8 d2 1f 00 00       	call   103da0 <memmove>
    name[len] = 0;
  101dce:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101dd1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101dd4:	c6 04 10 00          	movb   $0x0,(%eax,%edx,1)
  101dd8:	eb 81                	jmp    101d5b <namex+0x9b>
      // Stop one level early.
      iunlock(ip);
      return ip;
    }
    if((next = dirlookup(ip, name, 0)) == 0){
      iunlockput(ip);
  101dda:	89 3c 24             	mov    %edi,(%esp)
  101ddd:	31 ff                	xor    %edi,%edi
  101ddf:	e8 dc fc ff ff       	call   101ac0 <iunlockput>
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
  101de4:	83 c4 2c             	add    $0x2c,%esp
  101de7:	89 f8                	mov    %edi,%eax
  101de9:	5b                   	pop    %ebx
  101dea:	5e                   	pop    %esi
  101deb:	5f                   	pop    %edi
  101dec:	5d                   	pop    %ebp
  101ded:	c3                   	ret    
namex(char *path, int nameiparent, char *name)
{
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  101dee:	ba 01 00 00 00       	mov    $0x1,%edx
  101df3:	b8 01 00 00 00       	mov    $0x1,%eax
  101df8:	e8 d3 f2 ff ff       	call   1010d0 <iget>
  101dfd:	89 c7                	mov    %eax,%edi
  101dff:	e9 ef fe ff ff       	jmp    101cf3 <namex+0x33>
      iunlockput(ip);
      return 0;
    }
    if(nameiparent && *path == '\0'){
      // Stop one level early.
      iunlock(ip);
  101e04:	89 3c 24             	mov    %edi,(%esp)
  101e07:	e8 64 f9 ff ff       	call   101770 <iunlock>
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
  101e0c:	83 c4 2c             	add    $0x2c,%esp
  101e0f:	89 f8                	mov    %edi,%eax
  101e11:	5b                   	pop    %ebx
  101e12:	5e                   	pop    %esi
  101e13:	5f                   	pop    %edi
  101e14:	5d                   	pop    %ebp
  101e15:	c3                   	ret    
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
    iput(ip);
  101e16:	89 3c 24             	mov    %edi,(%esp)
  101e19:	31 ff                	xor    %edi,%edi
  101e1b:	e8 60 fa ff ff       	call   101880 <iput>
    return 0;
  101e20:	e9 e4 fe ff ff       	jmp    101d09 <namex+0x49>
  101e25:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101e29:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101e30 <nameiparent>:
  return namex(path, 0, name);
}

struct inode*
nameiparent(char *path, char *name)
{
  101e30:	55                   	push   %ebp
  return namex(path, 1, name);
  101e31:	ba 01 00 00 00       	mov    $0x1,%edx
  return namex(path, 0, name);
}

struct inode*
nameiparent(char *path, char *name)
{
  101e36:	89 e5                	mov    %esp,%ebp
  101e38:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
  101e3b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  101e3e:	8b 45 08             	mov    0x8(%ebp),%eax
}
  101e41:	c9                   	leave  
}

struct inode*
nameiparent(char *path, char *name)
{
  return namex(path, 1, name);
  101e42:	e9 79 fe ff ff       	jmp    101cc0 <namex>
  101e47:	89 f6                	mov    %esi,%esi
  101e49:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101e50 <namei>:
  return ip;
}

struct inode*
namei(char *path)
{
  101e50:	55                   	push   %ebp
  char name[DIRSIZ];
  return namex(path, 0, name);
  101e51:	31 d2                	xor    %edx,%edx
  return ip;
}

struct inode*
namei(char *path)
{
  101e53:	89 e5                	mov    %esp,%ebp
  101e55:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
  101e58:	8b 45 08             	mov    0x8(%ebp),%eax
  101e5b:	8d 4d ea             	lea    -0x16(%ebp),%ecx
  101e5e:	e8 5d fe ff ff       	call   101cc0 <namex>
}
  101e63:	c9                   	leave  
  101e64:	c3                   	ret    
  101e65:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101e69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00101e70 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
  101e70:	55                   	push   %ebp
  101e71:	89 e5                	mov    %esp,%ebp
  101e73:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
  101e76:	c7 44 24 04 0f 67 10 	movl   $0x10670f,0x4(%esp)
  101e7d:	00 
  101e7e:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  101e85:	e8 66 1c 00 00       	call   103af0 <initlock>
}
  101e8a:	c9                   	leave  
  101e8b:	c3                   	ret    
  101e8c:	90                   	nop
  101e8d:	90                   	nop
  101e8e:	90                   	nop
  101e8f:	90                   	nop

00101e90 <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
  101e90:	55                   	push   %ebp
  101e91:	89 e5                	mov    %esp,%ebp
  101e93:	56                   	push   %esi
  101e94:	89 c6                	mov    %eax,%esi
  101e96:	83 ec 14             	sub    $0x14,%esp
  if(b == 0)
  101e99:	85 c0                	test   %eax,%eax
  101e9b:	0f 84 8d 00 00 00    	je     101f2e <idestart+0x9e>
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  101ea1:	ba f7 01 00 00       	mov    $0x1f7,%edx
  101ea6:	66 90                	xchg   %ax,%ax
  101ea8:	ec                   	in     (%dx),%al
static int
idewait(int checkerr)
{
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
  101ea9:	25 c0 00 00 00       	and    $0xc0,%eax
  101eae:	83 f8 40             	cmp    $0x40,%eax
  101eb1:	75 f5                	jne    101ea8 <idestart+0x18>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  101eb3:	ba f6 03 00 00       	mov    $0x3f6,%edx
  101eb8:	31 c0                	xor    %eax,%eax
  101eba:	ee                   	out    %al,(%dx)
  101ebb:	ba f2 01 00 00       	mov    $0x1f2,%edx
  101ec0:	b8 01 00 00 00       	mov    $0x1,%eax
  101ec5:	ee                   	out    %al,(%dx)
    panic("idestart");

  idewait(0);
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, 1);  // number of sectors
  outb(0x1f3, b->sector & 0xff);
  101ec6:	8b 4e 08             	mov    0x8(%esi),%ecx
  101ec9:	b2 f3                	mov    $0xf3,%dl
  101ecb:	89 c8                	mov    %ecx,%eax
  101ecd:	ee                   	out    %al,(%dx)
  101ece:	89 c8                	mov    %ecx,%eax
  101ed0:	b2 f4                	mov    $0xf4,%dl
  101ed2:	c1 e8 08             	shr    $0x8,%eax
  101ed5:	ee                   	out    %al,(%dx)
  101ed6:	89 c8                	mov    %ecx,%eax
  101ed8:	b2 f5                	mov    $0xf5,%dl
  101eda:	c1 e8 10             	shr    $0x10,%eax
  101edd:	ee                   	out    %al,(%dx)
  101ede:	8b 46 04             	mov    0x4(%esi),%eax
  101ee1:	c1 e9 18             	shr    $0x18,%ecx
  101ee4:	b2 f6                	mov    $0xf6,%dl
  101ee6:	83 e1 0f             	and    $0xf,%ecx
  101ee9:	83 e0 01             	and    $0x1,%eax
  101eec:	c1 e0 04             	shl    $0x4,%eax
  101eef:	09 c8                	or     %ecx,%eax
  101ef1:	83 c8 e0             	or     $0xffffffe0,%eax
  101ef4:	ee                   	out    %al,(%dx)
  outb(0x1f4, (b->sector >> 8) & 0xff);
  outb(0x1f5, (b->sector >> 16) & 0xff);
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
  if(b->flags & B_DIRTY){
  101ef5:	f6 06 04             	testb  $0x4,(%esi)
  101ef8:	75 16                	jne    101f10 <idestart+0x80>
  101efa:	ba f7 01 00 00       	mov    $0x1f7,%edx
  101eff:	b8 20 00 00 00       	mov    $0x20,%eax
  101f04:	ee                   	out    %al,(%dx)
    outb(0x1f7, IDE_CMD_WRITE);
    outsl(0x1f0, b->data, 512/4);
  } else {
    outb(0x1f7, IDE_CMD_READ);
  }
}
  101f05:	83 c4 14             	add    $0x14,%esp
  101f08:	5e                   	pop    %esi
  101f09:	5d                   	pop    %ebp
  101f0a:	c3                   	ret    
  101f0b:	90                   	nop
  101f0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  101f10:	b2 f7                	mov    $0xf7,%dl
  101f12:	b8 30 00 00 00       	mov    $0x30,%eax
  101f17:	ee                   	out    %al,(%dx)
}

static inline void
outsl(int port, const void *addr, int cnt)
{
  asm volatile("cld; rep outsl" :
  101f18:	b9 80 00 00 00       	mov    $0x80,%ecx
  101f1d:	83 c6 18             	add    $0x18,%esi
  101f20:	ba f0 01 00 00       	mov    $0x1f0,%edx
  101f25:	fc                   	cld    
  101f26:	f3 6f                	rep outsl %ds:(%esi),(%dx)
  101f28:	83 c4 14             	add    $0x14,%esp
  101f2b:	5e                   	pop    %esi
  101f2c:	5d                   	pop    %ebp
  101f2d:	c3                   	ret    
// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
  if(b == 0)
    panic("idestart");
  101f2e:	c7 04 24 16 67 10 00 	movl   $0x106716,(%esp)
  101f35:	e8 e6 e9 ff ff       	call   100920 <panic>
  101f3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00101f40 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
  101f40:	55                   	push   %ebp
  101f41:	89 e5                	mov    %esp,%ebp
  101f43:	53                   	push   %ebx
  101f44:	83 ec 14             	sub    $0x14,%esp
  101f47:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!(b->flags & B_BUSY))
  101f4a:	8b 03                	mov    (%ebx),%eax
  101f4c:	a8 01                	test   $0x1,%al
  101f4e:	0f 84 90 00 00 00    	je     101fe4 <iderw+0xa4>
    panic("iderw: buf not busy");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
  101f54:	83 e0 06             	and    $0x6,%eax
  101f57:	83 f8 02             	cmp    $0x2,%eax
  101f5a:	0f 84 9c 00 00 00    	je     101ffc <iderw+0xbc>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
  101f60:	8b 53 04             	mov    0x4(%ebx),%edx
  101f63:	85 d2                	test   %edx,%edx
  101f65:	74 0d                	je     101f74 <iderw+0x34>
  101f67:	a1 b8 78 10 00       	mov    0x1078b8,%eax
  101f6c:	85 c0                	test   %eax,%eax
  101f6e:	0f 84 7c 00 00 00    	je     101ff0 <iderw+0xb0>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);
  101f74:	c7 04 24 80 78 10 00 	movl   $0x107880,(%esp)
  101f7b:	e8 00 1d 00 00       	call   103c80 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)
  101f80:	ba b4 78 10 00       	mov    $0x1078b4,%edx
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);

  // Append b to idequeue.
  b->qnext = 0;
  101f85:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  101f8c:	a1 b4 78 10 00       	mov    0x1078b4,%eax
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)
  101f91:	85 c0                	test   %eax,%eax
  101f93:	74 0d                	je     101fa2 <iderw+0x62>
  101f95:	8d 76 00             	lea    0x0(%esi),%esi
  101f98:	8d 50 14             	lea    0x14(%eax),%edx
  101f9b:	8b 40 14             	mov    0x14(%eax),%eax
  101f9e:	85 c0                	test   %eax,%eax
  101fa0:	75 f6                	jne    101f98 <iderw+0x58>
    ;
  *pp = b;
  101fa2:	89 1a                	mov    %ebx,(%edx)
  
  // Start disk if necessary.
  if(idequeue == b)
  101fa4:	39 1d b4 78 10 00    	cmp    %ebx,0x1078b4
  101faa:	75 14                	jne    101fc0 <iderw+0x80>
  101fac:	eb 2d                	jmp    101fdb <iderw+0x9b>
  101fae:	66 90                	xchg   %ax,%ax
    idestart(b);
  
  // Wait for request to finish.
  // Assuming will not sleep too long: ignore proc->killed.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
  101fb0:	c7 44 24 04 80 78 10 	movl   $0x107880,0x4(%esp)
  101fb7:	00 
  101fb8:	89 1c 24             	mov    %ebx,(%esp)
  101fbb:	e8 90 12 00 00       	call   103250 <sleep>
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  // Assuming will not sleep too long: ignore proc->killed.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
  101fc0:	8b 03                	mov    (%ebx),%eax
  101fc2:	83 e0 06             	and    $0x6,%eax
  101fc5:	83 f8 02             	cmp    $0x2,%eax
  101fc8:	75 e6                	jne    101fb0 <iderw+0x70>
    sleep(b, &idelock);
  }

  release(&idelock);
  101fca:	c7 45 08 80 78 10 00 	movl   $0x107880,0x8(%ebp)
}
  101fd1:	83 c4 14             	add    $0x14,%esp
  101fd4:	5b                   	pop    %ebx
  101fd5:	5d                   	pop    %ebp
  // Assuming will not sleep too long: ignore proc->killed.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
  }

  release(&idelock);
  101fd6:	e9 55 1c 00 00       	jmp    103c30 <release>
    ;
  *pp = b;
  
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  101fdb:	89 d8                	mov    %ebx,%eax
  101fdd:	e8 ae fe ff ff       	call   101e90 <idestart>
  101fe2:	eb dc                	jmp    101fc0 <iderw+0x80>
iderw(struct buf *b)
{
  struct buf **pp;

  if(!(b->flags & B_BUSY))
    panic("iderw: buf not busy");
  101fe4:	c7 04 24 1f 67 10 00 	movl   $0x10671f,(%esp)
  101feb:	e8 30 e9 ff ff       	call   100920 <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
    panic("iderw: ide disk 1 not present");
  101ff0:	c7 04 24 48 67 10 00 	movl   $0x106748,(%esp)
  101ff7:	e8 24 e9 ff ff       	call   100920 <panic>
  struct buf **pp;

  if(!(b->flags & B_BUSY))
    panic("iderw: buf not busy");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("iderw: nothing to do");
  101ffc:	c7 04 24 33 67 10 00 	movl   $0x106733,(%esp)
  102003:	e8 18 e9 ff ff       	call   100920 <panic>
  102008:	90                   	nop
  102009:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102010 <ideintr>:
}

// Interrupt handler.
void
ideintr(void)
{
  102010:	55                   	push   %ebp
  102011:	89 e5                	mov    %esp,%ebp
  102013:	57                   	push   %edi
  102014:	53                   	push   %ebx
  102015:	83 ec 10             	sub    $0x10,%esp
  struct buf *b;

  // Take first buffer off queue.
  acquire(&idelock);
  102018:	c7 04 24 80 78 10 00 	movl   $0x107880,(%esp)
  10201f:	e8 5c 1c 00 00       	call   103c80 <acquire>
  if((b = idequeue) == 0){
  102024:	8b 1d b4 78 10 00    	mov    0x1078b4,%ebx
  10202a:	85 db                	test   %ebx,%ebx
  10202c:	74 2d                	je     10205b <ideintr+0x4b>
    release(&idelock);
    // cprintf("spurious IDE interrupt\n");
    return;
  }
  idequeue = b->qnext;
  10202e:	8b 43 14             	mov    0x14(%ebx),%eax
  102031:	a3 b4 78 10 00       	mov    %eax,0x1078b4

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
  102036:	8b 0b                	mov    (%ebx),%ecx
  102038:	f6 c1 04             	test   $0x4,%cl
  10203b:	74 33                	je     102070 <ideintr+0x60>
    insl(0x1f0, b->data, 512/4);
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
  b->flags &= ~B_DIRTY;
  10203d:	83 c9 02             	or     $0x2,%ecx
  102040:	83 e1 fb             	and    $0xfffffffb,%ecx
  102043:	89 0b                	mov    %ecx,(%ebx)
  wakeup(b);
  102045:	89 1c 24             	mov    %ebx,(%esp)
  102048:	e8 e3 10 00 00       	call   103130 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
  10204d:	a1 b4 78 10 00       	mov    0x1078b4,%eax
  102052:	85 c0                	test   %eax,%eax
  102054:	74 05                	je     10205b <ideintr+0x4b>
    idestart(idequeue);
  102056:	e8 35 fe ff ff       	call   101e90 <idestart>

  release(&idelock);
  10205b:	c7 04 24 80 78 10 00 	movl   $0x107880,(%esp)
  102062:	e8 c9 1b 00 00       	call   103c30 <release>
}
  102067:	83 c4 10             	add    $0x10,%esp
  10206a:	5b                   	pop    %ebx
  10206b:	5f                   	pop    %edi
  10206c:	5d                   	pop    %ebp
  10206d:	c3                   	ret    
  10206e:	66 90                	xchg   %ax,%ax
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  102070:	ba f7 01 00 00       	mov    $0x1f7,%edx
  102075:	8d 76 00             	lea    0x0(%esi),%esi
  102078:	ec                   	in     (%dx),%al
static int
idewait(int checkerr)
{
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
  102079:	0f b6 c0             	movzbl %al,%eax
  10207c:	89 c7                	mov    %eax,%edi
  10207e:	81 e7 c0 00 00 00    	and    $0xc0,%edi
  102084:	83 ff 40             	cmp    $0x40,%edi
  102087:	75 ef                	jne    102078 <ideintr+0x68>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
  102089:	a8 21                	test   $0x21,%al
  10208b:	75 b0                	jne    10203d <ideintr+0x2d>
}

static inline void
insl(int port, void *addr, int cnt)
{
  asm volatile("cld; rep insl" :
  10208d:	8d 7b 18             	lea    0x18(%ebx),%edi
  102090:	b9 80 00 00 00       	mov    $0x80,%ecx
  102095:	ba f0 01 00 00       	mov    $0x1f0,%edx
  10209a:	fc                   	cld    
  10209b:	f3 6d                	rep insl (%dx),%es:(%edi)
  10209d:	8b 0b                	mov    (%ebx),%ecx
  10209f:	eb 9c                	jmp    10203d <ideintr+0x2d>
  1020a1:	eb 0d                	jmp    1020b0 <ideinit>
  1020a3:	90                   	nop
  1020a4:	90                   	nop
  1020a5:	90                   	nop
  1020a6:	90                   	nop
  1020a7:	90                   	nop
  1020a8:	90                   	nop
  1020a9:	90                   	nop
  1020aa:	90                   	nop
  1020ab:	90                   	nop
  1020ac:	90                   	nop
  1020ad:	90                   	nop
  1020ae:	90                   	nop
  1020af:	90                   	nop

001020b0 <ideinit>:
  return 0;
}

void
ideinit(void)
{
  1020b0:	55                   	push   %ebp
  1020b1:	89 e5                	mov    %esp,%ebp
  1020b3:	83 ec 18             	sub    $0x18,%esp
  int i;

  initlock(&idelock, "ide");
  1020b6:	c7 44 24 04 66 67 10 	movl   $0x106766,0x4(%esp)
  1020bd:	00 
  1020be:	c7 04 24 80 78 10 00 	movl   $0x107880,(%esp)
  1020c5:	e8 26 1a 00 00       	call   103af0 <initlock>
  picenable(IRQ_IDE);
  1020ca:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
  1020d1:	e8 ba 0a 00 00       	call   102b90 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
  1020d6:	a1 00 c1 10 00       	mov    0x10c100,%eax
  1020db:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
  1020e2:	83 e8 01             	sub    $0x1,%eax
  1020e5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1020e9:	e8 52 00 00 00       	call   102140 <ioapicenable>
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  1020ee:	ba f7 01 00 00       	mov    $0x1f7,%edx
  1020f3:	90                   	nop
  1020f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1020f8:	ec                   	in     (%dx),%al
static int
idewait(int checkerr)
{
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
  1020f9:	25 c0 00 00 00       	and    $0xc0,%eax
  1020fe:	83 f8 40             	cmp    $0x40,%eax
  102101:	75 f5                	jne    1020f8 <ideinit+0x48>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  102103:	ba f6 01 00 00       	mov    $0x1f6,%edx
  102108:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  10210d:	ee                   	out    %al,(%dx)
  10210e:	31 c9                	xor    %ecx,%ecx
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  102110:	b2 f7                	mov    $0xf7,%dl
  102112:	eb 0f                	jmp    102123 <ideinit+0x73>
  102114:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
  102118:	83 c1 01             	add    $0x1,%ecx
  10211b:	81 f9 e8 03 00 00    	cmp    $0x3e8,%ecx
  102121:	74 0f                	je     102132 <ideinit+0x82>
  102123:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
  102124:	84 c0                	test   %al,%al
  102126:	74 f0                	je     102118 <ideinit+0x68>
      havedisk1 = 1;
  102128:	c7 05 b8 78 10 00 01 	movl   $0x1,0x1078b8
  10212f:	00 00 00 
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  102132:	ba f6 01 00 00       	mov    $0x1f6,%edx
  102137:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
  10213c:	ee                   	out    %al,(%dx)
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
}
  10213d:	c9                   	leave  
  10213e:	c3                   	ret    
  10213f:	90                   	nop

00102140 <ioapicenable>:
}

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
  102140:	8b 15 04 bb 10 00    	mov    0x10bb04,%edx
  }
}

void
ioapicenable(int irq, int cpunum)
{
  102146:	55                   	push   %ebp
  102147:	89 e5                	mov    %esp,%ebp
  102149:	8b 45 08             	mov    0x8(%ebp),%eax
  if(!ismp)
  10214c:	85 d2                	test   %edx,%edx
  10214e:	74 31                	je     102181 <ioapicenable+0x41>
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  102150:	8b 15 b4 ba 10 00    	mov    0x10bab4,%edx
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  102156:	8d 48 20             	lea    0x20(%eax),%ecx
  102159:	8d 44 00 10          	lea    0x10(%eax,%eax,1),%eax
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  10215d:	89 02                	mov    %eax,(%edx)
  ioapic->data = data;
  10215f:	8b 15 b4 ba 10 00    	mov    0x10bab4,%edx
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  102165:	83 c0 01             	add    $0x1,%eax
  ioapic->data = data;
  102168:	89 4a 10             	mov    %ecx,0x10(%edx)
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  10216b:	8b 0d b4 ba 10 00    	mov    0x10bab4,%ecx

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
  102171:	8b 55 0c             	mov    0xc(%ebp),%edx
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  102174:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
  102176:	a1 b4 ba 10 00       	mov    0x10bab4,%eax

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
  10217b:	c1 e2 18             	shl    $0x18,%edx

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  ioapic->data = data;
  10217e:	89 50 10             	mov    %edx,0x10(%eax)
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
  102181:	5d                   	pop    %ebp
  102182:	c3                   	ret    
  102183:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102189:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102190 <ioapicinit>:
  ioapic->data = data;
}

void
ioapicinit(void)
{
  102190:	55                   	push   %ebp
  102191:	89 e5                	mov    %esp,%ebp
  102193:	56                   	push   %esi
  102194:	53                   	push   %ebx
  102195:	83 ec 10             	sub    $0x10,%esp
  int i, id, maxintr;

  if(!ismp)
  102198:	8b 0d 04 bb 10 00    	mov    0x10bb04,%ecx
  10219e:	85 c9                	test   %ecx,%ecx
  1021a0:	0f 84 9e 00 00 00    	je     102244 <ioapicinit+0xb4>
};

static uint
ioapicread(int reg)
{
  ioapic->reg = reg;
  1021a6:	c7 05 00 00 c0 fe 01 	movl   $0x1,0xfec00000
  1021ad:	00 00 00 
  return ioapic->data;
  1021b0:	8b 35 10 00 c0 fe    	mov    0xfec00010,%esi
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
  id = ioapicread(REG_ID) >> 24;
  if(id != ioapicid)
  1021b6:	bb 00 00 c0 fe       	mov    $0xfec00000,%ebx
};

static uint
ioapicread(int reg)
{
  ioapic->reg = reg;
  1021bb:	c7 05 00 00 c0 fe 00 	movl   $0x0,0xfec00000
  1021c2:	00 00 00 
  return ioapic->data;
  1021c5:	a1 10 00 c0 fe       	mov    0xfec00010,%eax
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
  id = ioapicread(REG_ID) >> 24;
  if(id != ioapicid)
  1021ca:	0f b6 15 00 bb 10 00 	movzbl 0x10bb00,%edx
  int i, id, maxintr;

  if(!ismp)
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
  1021d1:	c7 05 b4 ba 10 00 00 	movl   $0xfec00000,0x10bab4
  1021d8:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
  1021db:	c1 ee 10             	shr    $0x10,%esi
  id = ioapicread(REG_ID) >> 24;
  if(id != ioapicid)
  1021de:	c1 e8 18             	shr    $0x18,%eax

  if(!ismp)
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
  1021e1:	81 e6 ff 00 00 00    	and    $0xff,%esi
  id = ioapicread(REG_ID) >> 24;
  if(id != ioapicid)
  1021e7:	39 c2                	cmp    %eax,%edx
  1021e9:	74 12                	je     1021fd <ioapicinit+0x6d>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
  1021eb:	c7 04 24 6c 67 10 00 	movl   $0x10676c,(%esp)
  1021f2:	e8 39 e3 ff ff       	call   100530 <cprintf>
  1021f7:	8b 1d b4 ba 10 00    	mov    0x10bab4,%ebx
  1021fd:	ba 10 00 00 00       	mov    $0x10,%edx
  102202:	31 c0                	xor    %eax,%eax
  102204:	eb 08                	jmp    10220e <ioapicinit+0x7e>
  102206:	66 90                	xchg   %ax,%ax

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
  102208:	8b 1d b4 ba 10 00    	mov    0x10bab4,%ebx
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  10220e:	89 13                	mov    %edx,(%ebx)
  ioapic->data = data;
  102210:	8b 1d b4 ba 10 00    	mov    0x10bab4,%ebx
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  102216:	8d 48 20             	lea    0x20(%eax),%ecx
  102219:	81 c9 00 00 01 00    	or     $0x10000,%ecx
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
  10221f:	83 c0 01             	add    $0x1,%eax

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  ioapic->data = data;
  102222:	89 4b 10             	mov    %ecx,0x10(%ebx)
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  102225:	8b 0d b4 ba 10 00    	mov    0x10bab4,%ecx
  10222b:	8d 5a 01             	lea    0x1(%edx),%ebx
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
  10222e:	83 c2 02             	add    $0x2,%edx
  102231:	39 c6                	cmp    %eax,%esi
}

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
  102233:	89 19                	mov    %ebx,(%ecx)
  ioapic->data = data;
  102235:	8b 0d b4 ba 10 00    	mov    0x10bab4,%ecx
  10223b:	c7 41 10 00 00 00 00 	movl   $0x0,0x10(%ecx)
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
  102242:	7d c4                	jge    102208 <ioapicinit+0x78>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
  102244:	83 c4 10             	add    $0x10,%esp
  102247:	5b                   	pop    %ebx
  102248:	5e                   	pop    %esi
  102249:	5d                   	pop    %ebp
  10224a:	c3                   	ret    
  10224b:	90                   	nop
  10224c:	90                   	nop
  10224d:	90                   	nop
  10224e:	90                   	nop
  10224f:	90                   	nop

00102250 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
  102250:	55                   	push   %ebp
  102251:	89 e5                	mov    %esp,%ebp
  102253:	53                   	push   %ebx
  102254:	83 ec 14             	sub    $0x14,%esp
  struct run *r;

  acquire(&kmem.lock);
  102257:	c7 04 24 c0 ba 10 00 	movl   $0x10bac0,(%esp)
  10225e:	e8 1d 1a 00 00       	call   103c80 <acquire>
  r = kmem.freelist;
  102263:	8b 1d f4 ba 10 00    	mov    0x10baf4,%ebx
  if(r)
  102269:	85 db                	test   %ebx,%ebx
  10226b:	74 07                	je     102274 <kalloc+0x24>
    kmem.freelist = r->next;
  10226d:	8b 03                	mov    (%ebx),%eax
  10226f:	a3 f4 ba 10 00       	mov    %eax,0x10baf4
  release(&kmem.lock);
  102274:	c7 04 24 c0 ba 10 00 	movl   $0x10bac0,(%esp)
  10227b:	e8 b0 19 00 00       	call   103c30 <release>
  return (char*)r;
}
  102280:	89 d8                	mov    %ebx,%eax
  102282:	83 c4 14             	add    $0x14,%esp
  102285:	5b                   	pop    %ebx
  102286:	5d                   	pop    %ebp
  102287:	c3                   	ret    
  102288:	90                   	nop
  102289:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102290 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
  102290:	55                   	push   %ebp
  102291:	89 e5                	mov    %esp,%ebp
  102293:	53                   	push   %ebx
  102294:	83 ec 14             	sub    $0x14,%esp
  102297:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || (uint)v >= PHYSTOP) 
  10229a:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
  1022a0:	75 52                	jne    1022f4 <kfree+0x64>
  1022a2:	81 fb ff ff ff 00    	cmp    $0xffffff,%ebx
  1022a8:	77 4a                	ja     1022f4 <kfree+0x64>
  1022aa:	81 fb a4 e8 10 00    	cmp    $0x10e8a4,%ebx
  1022b0:	72 42                	jb     1022f4 <kfree+0x64>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
  1022b2:	89 1c 24             	mov    %ebx,(%esp)
  1022b5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1022bc:	00 
  1022bd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1022c4:	00 
  1022c5:	e8 56 1a 00 00       	call   103d20 <memset>

  acquire(&kmem.lock);
  1022ca:	c7 04 24 c0 ba 10 00 	movl   $0x10bac0,(%esp)
  1022d1:	e8 aa 19 00 00       	call   103c80 <acquire>
  r = (struct run*)v;
  r->next = kmem.freelist;
  1022d6:	a1 f4 ba 10 00       	mov    0x10baf4,%eax
  1022db:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
  1022dd:	89 1d f4 ba 10 00    	mov    %ebx,0x10baf4
  release(&kmem.lock);
  1022e3:	c7 45 08 c0 ba 10 00 	movl   $0x10bac0,0x8(%ebp)
}
  1022ea:	83 c4 14             	add    $0x14,%esp
  1022ed:	5b                   	pop    %ebx
  1022ee:	5d                   	pop    %ebp

  acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
  1022ef:	e9 3c 19 00 00       	jmp    103c30 <release>
kfree(char *v)
{
  struct run *r;

  if((uint)v % PGSIZE || v < end || (uint)v >= PHYSTOP) 
    panic("kfree");
  1022f4:	c7 04 24 9e 67 10 00 	movl   $0x10679e,(%esp)
  1022fb:	e8 20 e6 ff ff       	call   100920 <panic>

00102300 <kinit>:
extern char end[]; // first address after kernel loaded from ELF file

// Initialize free list of physical pages.
void
kinit(void)
{
  102300:	55                   	push   %ebp
  102301:	89 e5                	mov    %esp,%ebp
  102303:	53                   	push   %ebx
  102304:	83 ec 14             	sub    $0x14,%esp
  char *p;

  initlock(&kmem.lock, "kmem");
  102307:	c7 44 24 04 a4 67 10 	movl   $0x1067a4,0x4(%esp)
  10230e:	00 
  10230f:	c7 04 24 c0 ba 10 00 	movl   $0x10bac0,(%esp)
  102316:	e8 d5 17 00 00       	call   103af0 <initlock>
  p = (char*)PGROUNDUP((uint)end);
  10231b:	ba a3 f8 10 00       	mov    $0x10f8a3,%edx
  102320:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  for(; p + PGSIZE <= (char*)PHYSTOP; p += PGSIZE)
  102326:	8d 9a 00 10 00 00    	lea    0x1000(%edx),%ebx
  10232c:	81 fb 00 00 00 01    	cmp    $0x1000000,%ebx
  102332:	76 08                	jbe    10233c <kinit+0x3c>
  102334:	eb 1b                	jmp    102351 <kinit+0x51>
  102336:	66 90                	xchg   %ax,%ax
  102338:	89 da                	mov    %ebx,%edx
  10233a:	89 c3                	mov    %eax,%ebx
    kfree(p);
  10233c:	89 14 24             	mov    %edx,(%esp)
  10233f:	e8 4c ff ff ff       	call   102290 <kfree>
{
  char *p;

  initlock(&kmem.lock, "kmem");
  p = (char*)PGROUNDUP((uint)end);
  for(; p + PGSIZE <= (char*)PHYSTOP; p += PGSIZE)
  102344:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
  10234a:	3d 00 00 00 01       	cmp    $0x1000000,%eax
  10234f:	76 e7                	jbe    102338 <kinit+0x38>
    kfree(p);
}
  102351:	83 c4 14             	add    $0x14,%esp
  102354:	5b                   	pop    %ebx
  102355:	5d                   	pop    %ebp
  102356:	c3                   	ret    
  102357:	90                   	nop
  102358:	90                   	nop
  102359:	90                   	nop
  10235a:	90                   	nop
  10235b:	90                   	nop
  10235c:	90                   	nop
  10235d:	90                   	nop
  10235e:	90                   	nop
  10235f:	90                   	nop

00102360 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
  102360:	55                   	push   %ebp
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  102361:	ba 64 00 00 00       	mov    $0x64,%edx
  102366:	89 e5                	mov    %esp,%ebp
  102368:	ec                   	in     (%dx),%al
  102369:	89 c2                	mov    %eax,%edx
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
  10236b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102370:	83 e2 01             	and    $0x1,%edx
  102373:	74 41                	je     1023b6 <kbdgetc+0x56>
  102375:	ba 60 00 00 00       	mov    $0x60,%edx
  10237a:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
  10237b:	0f b6 c0             	movzbl %al,%eax

  if(data == 0xE0){
  10237e:	3d e0 00 00 00       	cmp    $0xe0,%eax
  102383:	0f 84 7f 00 00 00    	je     102408 <kbdgetc+0xa8>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
  102389:	84 c0                	test   %al,%al
  10238b:	79 2b                	jns    1023b8 <kbdgetc+0x58>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
  10238d:	8b 15 bc 78 10 00    	mov    0x1078bc,%edx
  102393:	89 c1                	mov    %eax,%ecx
  102395:	83 e1 7f             	and    $0x7f,%ecx
  102398:	f6 c2 40             	test   $0x40,%dl
  10239b:	0f 44 c1             	cmove  %ecx,%eax
    shift &= ~(shiftcode[data] | E0ESC);
  10239e:	0f b6 80 c0 67 10 00 	movzbl 0x1067c0(%eax),%eax
  1023a5:	83 c8 40             	or     $0x40,%eax
  1023a8:	0f b6 c0             	movzbl %al,%eax
  1023ab:	f7 d0                	not    %eax
  1023ad:	21 d0                	and    %edx,%eax
  1023af:	a3 bc 78 10 00       	mov    %eax,0x1078bc
  1023b4:	31 c0                	xor    %eax,%eax
      c += 'A' - 'a';
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
  1023b6:	5d                   	pop    %ebp
  1023b7:	c3                   	ret    
  } else if(data & 0x80){
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
  1023b8:	8b 0d bc 78 10 00    	mov    0x1078bc,%ecx
  1023be:	f6 c1 40             	test   $0x40,%cl
  1023c1:	74 05                	je     1023c8 <kbdgetc+0x68>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
  1023c3:	0c 80                	or     $0x80,%al
    shift &= ~E0ESC;
  1023c5:	83 e1 bf             	and    $0xffffffbf,%ecx
  }

  shift |= shiftcode[data];
  shift ^= togglecode[data];
  1023c8:	0f b6 90 c0 67 10 00 	movzbl 0x1067c0(%eax),%edx
  1023cf:	09 ca                	or     %ecx,%edx
  1023d1:	0f b6 88 c0 68 10 00 	movzbl 0x1068c0(%eax),%ecx
  1023d8:	31 ca                	xor    %ecx,%edx
  c = charcode[shift & (CTL | SHIFT)][data];
  1023da:	89 d1                	mov    %edx,%ecx
  1023dc:	83 e1 03             	and    $0x3,%ecx
  1023df:	8b 0c 8d c0 69 10 00 	mov    0x1069c0(,%ecx,4),%ecx
    data |= 0x80;
    shift &= ~E0ESC;
  }

  shift |= shiftcode[data];
  shift ^= togglecode[data];
  1023e6:	89 15 bc 78 10 00    	mov    %edx,0x1078bc
  c = charcode[shift & (CTL | SHIFT)][data];
  if(shift & CAPSLOCK){
  1023ec:	83 e2 08             	and    $0x8,%edx
    shift &= ~E0ESC;
  }

  shift |= shiftcode[data];
  shift ^= togglecode[data];
  c = charcode[shift & (CTL | SHIFT)][data];
  1023ef:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
  if(shift & CAPSLOCK){
  1023f3:	74 c1                	je     1023b6 <kbdgetc+0x56>
    if('a' <= c && c <= 'z')
  1023f5:	8d 50 9f             	lea    -0x61(%eax),%edx
  1023f8:	83 fa 19             	cmp    $0x19,%edx
  1023fb:	77 1b                	ja     102418 <kbdgetc+0xb8>
      c += 'A' - 'a';
  1023fd:	83 e8 20             	sub    $0x20,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
  102400:	5d                   	pop    %ebp
  102401:	c3                   	ret    
  102402:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  if((st & KBS_DIB) == 0)
    return -1;
  data = inb(KBDATAP);

  if(data == 0xE0){
    shift |= E0ESC;
  102408:	30 c0                	xor    %al,%al
  10240a:	83 0d bc 78 10 00 40 	orl    $0x40,0x1078bc
      c += 'A' - 'a';
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
  102411:	5d                   	pop    %ebp
  102412:	c3                   	ret    
  102413:	90                   	nop
  102414:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  shift ^= togglecode[data];
  c = charcode[shift & (CTL | SHIFT)][data];
  if(shift & CAPSLOCK){
    if('a' <= c && c <= 'z')
      c += 'A' - 'a';
    else if('A' <= c && c <= 'Z')
  102418:	8d 48 bf             	lea    -0x41(%eax),%ecx
      c += 'a' - 'A';
  10241b:	8d 50 20             	lea    0x20(%eax),%edx
  10241e:	83 f9 19             	cmp    $0x19,%ecx
  102421:	0f 46 c2             	cmovbe %edx,%eax
  }
  return c;
}
  102424:	5d                   	pop    %ebp
  102425:	c3                   	ret    
  102426:	8d 76 00             	lea    0x0(%esi),%esi
  102429:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102430 <kbdintr>:

void
kbdintr(void)
{
  102430:	55                   	push   %ebp
  102431:	89 e5                	mov    %esp,%ebp
  102433:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
  102436:	c7 04 24 60 23 10 00 	movl   $0x102360,(%esp)
  10243d:	e8 4e e3 ff ff       	call   100790 <consoleintr>
}
  102442:	c9                   	leave  
  102443:	c3                   	ret    
  102444:	90                   	nop
  102445:	90                   	nop
  102446:	90                   	nop
  102447:	90                   	nop
  102448:	90                   	nop
  102449:	90                   	nop
  10244a:	90                   	nop
  10244b:	90                   	nop
  10244c:	90                   	nop
  10244d:	90                   	nop
  10244e:	90                   	nop
  10244f:	90                   	nop

00102450 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
  if(lapic)
  102450:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
}

// Acknowledge interrupt.
void
lapiceoi(void)
{
  102455:	55                   	push   %ebp
  102456:	89 e5                	mov    %esp,%ebp
  if(lapic)
  102458:	85 c0                	test   %eax,%eax
  10245a:	74 12                	je     10246e <lapiceoi+0x1e>
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10245c:	c7 80 b0 00 00 00 00 	movl   $0x0,0xb0(%eax)
  102463:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  102466:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10246b:	8b 40 20             	mov    0x20(%eax),%eax
void
lapiceoi(void)
{
  if(lapic)
    lapicw(EOI, 0);
}
  10246e:	5d                   	pop    %ebp
  10246f:	c3                   	ret    

00102470 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  102470:	55                   	push   %ebp
  102471:	89 e5                	mov    %esp,%ebp
}
  102473:	5d                   	pop    %ebp
  102474:	c3                   	ret    
  102475:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102479:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102480 <lapicstartap>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
  102480:	55                   	push   %ebp
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  102481:	ba 70 00 00 00       	mov    $0x70,%edx
  102486:	89 e5                	mov    %esp,%ebp
  102488:	b8 0f 00 00 00       	mov    $0xf,%eax
  10248d:	53                   	push   %ebx
  10248e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  102491:	0f b6 5d 08          	movzbl 0x8(%ebp),%ebx
  102495:	ee                   	out    %al,(%dx)
  102496:	b8 0a 00 00 00       	mov    $0xa,%eax
  10249b:	b2 71                	mov    $0x71,%dl
  10249d:	ee                   	out    %al,(%dx)
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
  outb(IO_RTC+1, 0x0A);
  wrv = (ushort*)(0x40<<4 | 0x67);  // Warm reset vector
  wrv[0] = 0;
  wrv[1] = addr >> 4;
  10249e:	89 c8                	mov    %ecx,%eax
  1024a0:	c1 e8 04             	shr    $0x4,%eax
  1024a3:	66 a3 69 04 00 00    	mov    %ax,0x469
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1024a9:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1024ae:	c1 e3 18             	shl    $0x18,%ebx
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
  outb(IO_RTC+1, 0x0A);
  wrv = (ushort*)(0x40<<4 | 0x67);  // Warm reset vector
  wrv[0] = 0;
  1024b1:	66 c7 05 67 04 00 00 	movw   $0x0,0x467
  1024b8:	00 00 

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  lapic[ID];  // wait for write to finish, by reading
  1024ba:	c1 e9 0c             	shr    $0xc,%ecx
  1024bd:	80 cd 06             	or     $0x6,%ch
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1024c0:	89 98 10 03 00 00    	mov    %ebx,0x310(%eax)
  lapic[ID];  // wait for write to finish, by reading
  1024c6:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1024cb:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1024ce:	c7 80 00 03 00 00 00 	movl   $0xc500,0x300(%eax)
  1024d5:	c5 00 00 
  lapic[ID];  // wait for write to finish, by reading
  1024d8:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1024dd:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1024e0:	c7 80 00 03 00 00 00 	movl   $0x8500,0x300(%eax)
  1024e7:	85 00 00 
  lapic[ID];  // wait for write to finish, by reading
  1024ea:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1024ef:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1024f2:	89 98 10 03 00 00    	mov    %ebx,0x310(%eax)
  lapic[ID];  // wait for write to finish, by reading
  1024f8:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1024fd:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  102500:	89 88 00 03 00 00    	mov    %ecx,0x300(%eax)
  lapic[ID];  // wait for write to finish, by reading
  102506:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10250b:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10250e:	89 98 10 03 00 00    	mov    %ebx,0x310(%eax)
  lapic[ID];  // wait for write to finish, by reading
  102514:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  102519:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10251c:	89 88 00 03 00 00    	mov    %ecx,0x300(%eax)
  lapic[ID];  // wait for write to finish, by reading
  102522:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  for(i = 0; i < 2; i++){
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
  102527:	5b                   	pop    %ebx
  102528:	5d                   	pop    %ebp

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  lapic[ID];  // wait for write to finish, by reading
  102529:	8b 40 20             	mov    0x20(%eax),%eax
  for(i = 0; i < 2; i++){
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
  10252c:	c3                   	ret    
  10252d:	8d 76 00             	lea    0x0(%esi),%esi

00102530 <cpunum>:
  lapicw(TPR, 0);
}

int
cpunum(void)
{
  102530:	55                   	push   %ebp
  102531:	89 e5                	mov    %esp,%ebp
  102533:	83 ec 18             	sub    $0x18,%esp

static inline uint
readeflags(void)
{
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
  102536:	9c                   	pushf  
  102537:	58                   	pop    %eax
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
  102538:	f6 c4 02             	test   $0x2,%ah
  10253b:	74 12                	je     10254f <cpunum+0x1f>
    static int n;
    if(n++ == 0)
  10253d:	a1 c0 78 10 00       	mov    0x1078c0,%eax
  102542:	8d 50 01             	lea    0x1(%eax),%edx
  102545:	85 c0                	test   %eax,%eax
  102547:	89 15 c0 78 10 00    	mov    %edx,0x1078c0
  10254d:	74 19                	je     102568 <cpunum+0x38>
      cprintf("cpu called from %x with interrupts enabled\n",
        __builtin_return_address(0));
  }

  if(lapic)
  10254f:	8b 15 f8 ba 10 00    	mov    0x10baf8,%edx
  102555:	31 c0                	xor    %eax,%eax
  102557:	85 d2                	test   %edx,%edx
  102559:	74 06                	je     102561 <cpunum+0x31>
    return lapic[ID]>>24;
  10255b:	8b 42 20             	mov    0x20(%edx),%eax
  10255e:	c1 e8 18             	shr    $0x18,%eax
  return 0;
}
  102561:	c9                   	leave  
  102562:	c3                   	ret    
  102563:	90                   	nop
  102564:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
    static int n;
    if(n++ == 0)
      cprintf("cpu called from %x with interrupts enabled\n",
  102568:	8b 45 04             	mov    0x4(%ebp),%eax
  10256b:	c7 04 24 d0 69 10 00 	movl   $0x1069d0,(%esp)
  102572:	89 44 24 04          	mov    %eax,0x4(%esp)
  102576:	e8 b5 df ff ff       	call   100530 <cprintf>
  10257b:	eb d2                	jmp    10254f <cpunum+0x1f>
  10257d:	8d 76 00             	lea    0x0(%esi),%esi

00102580 <lapicinit>:
  lapic[ID];  // wait for write to finish, by reading
}

void
lapicinit(int c)
{
  102580:	55                   	push   %ebp
  102581:	89 e5                	mov    %esp,%ebp
  102583:	83 ec 18             	sub    $0x18,%esp
  cprintf("lapicinit: %d 0x%x\n", c, lapic);
  102586:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10258b:	c7 04 24 fc 69 10 00 	movl   $0x1069fc,(%esp)
  102592:	89 44 24 08          	mov    %eax,0x8(%esp)
  102596:	8b 45 08             	mov    0x8(%ebp),%eax
  102599:	89 44 24 04          	mov    %eax,0x4(%esp)
  10259d:	e8 8e df ff ff       	call   100530 <cprintf>
  if(!lapic) 
  1025a2:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1025a7:	85 c0                	test   %eax,%eax
  1025a9:	0f 84 0a 01 00 00    	je     1026b9 <lapicinit+0x139>
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1025af:	c7 80 f0 00 00 00 3f 	movl   $0x13f,0xf0(%eax)
  1025b6:	01 00 00 
  lapic[ID];  // wait for write to finish, by reading
  1025b9:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1025be:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1025c1:	c7 80 e0 03 00 00 0b 	movl   $0xb,0x3e0(%eax)
  1025c8:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  1025cb:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1025d0:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1025d3:	c7 80 20 03 00 00 20 	movl   $0x20020,0x320(%eax)
  1025da:	00 02 00 
  lapic[ID];  // wait for write to finish, by reading
  1025dd:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1025e2:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1025e5:	c7 80 80 03 00 00 80 	movl   $0x989680,0x380(%eax)
  1025ec:	96 98 00 
  lapic[ID];  // wait for write to finish, by reading
  1025ef:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1025f4:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1025f7:	c7 80 50 03 00 00 00 	movl   $0x10000,0x350(%eax)
  1025fe:	00 01 00 
  lapic[ID];  // wait for write to finish, by reading
  102601:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  102606:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  102609:	c7 80 60 03 00 00 00 	movl   $0x10000,0x360(%eax)
  102610:	00 01 00 
  lapic[ID];  // wait for write to finish, by reading
  102613:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  102618:	8b 50 20             	mov    0x20(%eax),%edx
  lapicw(LINT0, MASKED);
  lapicw(LINT1, MASKED);

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
  10261b:	8b 50 30             	mov    0x30(%eax),%edx
  10261e:	c1 ea 10             	shr    $0x10,%edx
  102621:	80 fa 03             	cmp    $0x3,%dl
  102624:	0f 87 96 00 00 00    	ja     1026c0 <lapicinit+0x140>
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10262a:	c7 80 70 03 00 00 33 	movl   $0x33,0x370(%eax)
  102631:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  102634:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  102639:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10263c:	c7 80 80 02 00 00 00 	movl   $0x0,0x280(%eax)
  102643:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  102646:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10264b:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  10264e:	c7 80 80 02 00 00 00 	movl   $0x0,0x280(%eax)
  102655:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  102658:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10265d:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  102660:	c7 80 b0 00 00 00 00 	movl   $0x0,0xb0(%eax)
  102667:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  10266a:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  10266f:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  102672:	c7 80 10 03 00 00 00 	movl   $0x0,0x310(%eax)
  102679:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  10267c:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  102681:	8b 50 20             	mov    0x20(%eax),%edx
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  102684:	c7 80 00 03 00 00 00 	movl   $0x88500,0x300(%eax)
  10268b:	85 08 00 
  lapic[ID];  // wait for write to finish, by reading
  10268e:	8b 0d f8 ba 10 00    	mov    0x10baf8,%ecx
  102694:	8b 41 20             	mov    0x20(%ecx),%eax
  102697:	8d 91 00 03 00 00    	lea    0x300(%ecx),%edx
  10269d:	8d 76 00             	lea    0x0(%esi),%esi
  lapicw(EOI, 0);

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
  lapicw(ICRLO, BCAST | INIT | LEVEL);
  while(lapic[ICRLO] & DELIVS)
  1026a0:	8b 02                	mov    (%edx),%eax
  1026a2:	f6 c4 10             	test   $0x10,%ah
  1026a5:	75 f9                	jne    1026a0 <lapicinit+0x120>
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1026a7:	c7 81 80 00 00 00 00 	movl   $0x0,0x80(%ecx)
  1026ae:	00 00 00 
  lapic[ID];  // wait for write to finish, by reading
  1026b1:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1026b6:	8b 40 20             	mov    0x20(%eax),%eax
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
  1026b9:	c9                   	leave  
  1026ba:	c3                   	ret    
  1026bb:	90                   	nop
  1026bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
  lapic[index] = value;
  1026c0:	c7 80 40 03 00 00 00 	movl   $0x10000,0x340(%eax)
  1026c7:	00 01 00 
  lapic[ID];  // wait for write to finish, by reading
  1026ca:	a1 f8 ba 10 00       	mov    0x10baf8,%eax
  1026cf:	8b 50 20             	mov    0x20(%eax),%edx
  1026d2:	e9 53 ff ff ff       	jmp    10262a <lapicinit+0xaa>
  1026d7:	90                   	nop
  1026d8:	90                   	nop
  1026d9:	90                   	nop
  1026da:	90                   	nop
  1026db:	90                   	nop
  1026dc:	90                   	nop
  1026dd:	90                   	nop
  1026de:	90                   	nop
  1026df:	90                   	nop

001026e0 <mpmain>:
// Common CPU setup code.
// Bootstrap CPU comes here from mainc().
// Other CPUs jump here from bootother.S.
static void
mpmain(void)
{
  1026e0:	55                   	push   %ebp
  1026e1:	89 e5                	mov    %esp,%ebp
  1026e3:	53                   	push   %ebx
  1026e4:	83 ec 14             	sub    $0x14,%esp
  if(cpunum() != mpbcpu()){
  1026e7:	e8 44 fe ff ff       	call   102530 <cpunum>
  1026ec:	89 c3                	mov    %eax,%ebx
  1026ee:	e8 ed 01 00 00       	call   1028e0 <mpbcpu>
  1026f3:	39 c3                	cmp    %eax,%ebx
  1026f5:	74 16                	je     10270d <mpmain+0x2d>
    seginit();
  1026f7:	e8 b4 3d 00 00       	call   1064b0 <seginit>
  1026fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    lapicinit(cpunum());
  102700:	e8 2b fe ff ff       	call   102530 <cpunum>
  102705:	89 04 24             	mov    %eax,(%esp)
  102708:	e8 73 fe ff ff       	call   102580 <lapicinit>
  }
  vmenable();        // turn on paging
  10270d:	e8 5e 36 00 00       	call   105d70 <vmenable>
  cprintf("cpu%d: starting\n", cpu->id);
  102712:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  102718:	0f b6 00             	movzbl (%eax),%eax
  10271b:	c7 04 24 10 6a 10 00 	movl   $0x106a10,(%esp)
  102722:	89 44 24 04          	mov    %eax,0x4(%esp)
  102726:	e8 05 de ff ff       	call   100530 <cprintf>
  idtinit();       // load idt register
  10272b:	e8 50 27 00 00       	call   104e80 <idtinit>
  xchg(&cpu->booted, 1); // tell bootothers() we're up
  102730:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
  102737:	b8 01 00 00 00       	mov    $0x1,%eax
  10273c:	f0 87 82 a8 00 00 00 	lock xchg %eax,0xa8(%edx)
  scheduler();     // start running processes
  102743:	e8 18 0c 00 00       	call   103360 <scheduler>
  102748:	90                   	nop
  102749:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102750 <mainc>:

// Set up hardware and software.
// Runs only on the boostrap processor.
void
mainc(void)
{
  102750:	55                   	push   %ebp
  102751:	89 e5                	mov    %esp,%ebp
  102753:	53                   	push   %ebx
  102754:	83 ec 14             	sub    $0x14,%esp
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
  102757:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  10275d:	0f b6 00             	movzbl (%eax),%eax
  102760:	c7 04 24 21 6a 10 00 	movl   $0x106a21,(%esp)
  102767:	89 44 24 04          	mov    %eax,0x4(%esp)
  10276b:	e8 c0 dd ff ff       	call   100530 <cprintf>
  picinit();       // interrupt controller
  102770:	e8 4b 04 00 00       	call   102bc0 <picinit>
  ioapicinit();    // another interrupt controller
  102775:	e8 16 fa ff ff       	call   102190 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
  10277a:	e8 e1 da ff ff       	call   100260 <consoleinit>
  10277f:	90                   	nop
  uartinit();      // serial port
  102780:	e8 bb 2a 00 00       	call   105240 <uartinit>
  kvmalloc();      // initialize the kernel page table
  102785:	e8 66 38 00 00       	call   105ff0 <kvmalloc>
  pinit();         // process table
  10278a:	e8 41 13 00 00       	call   103ad0 <pinit>
  10278f:	90                   	nop
  tvinit();        // trap vectors
  102790:	e8 7b 29 00 00       	call   105110 <tvinit>
  binit();         // buffer cache
  102795:	e8 56 da ff ff       	call   1001f0 <binit>
  fileinit();      // file table
  10279a:	e8 b1 e8 ff ff       	call   101050 <fileinit>
  10279f:	90                   	nop
  iinit();         // inode cache
  1027a0:	e8 cb f6 ff ff       	call   101e70 <iinit>
  ideinit();       // disk
  1027a5:	e8 06 f9 ff ff       	call   1020b0 <ideinit>
  if(!ismp)
  1027aa:	a1 04 bb 10 00       	mov    0x10bb04,%eax
  1027af:	85 c0                	test   %eax,%eax
  1027b1:	0f 84 ae 00 00 00    	je     102865 <mainc+0x115>
    timerinit();   // uniprocessor timer
  userinit();      // first user process
  1027b7:	e8 24 12 00 00       	call   1039e0 <userinit>

  // Write bootstrap code to unused memory at 0x7000.
  // The linker has placed the image of bootother.S in
  // _binary_bootother_start.
  code = (uchar*)0x7000;
  memmove(code, _binary_bootother_start, (uint)_binary_bootother_size);
  1027bc:	c7 44 24 08 6a 00 00 	movl   $0x6a,0x8(%esp)
  1027c3:	00 
  1027c4:	c7 44 24 04 9c 77 10 	movl   $0x10779c,0x4(%esp)
  1027cb:	00 
  1027cc:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
  1027d3:	e8 c8 15 00 00       	call   103da0 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
  1027d8:	69 05 00 c1 10 00 bc 	imul   $0xbc,0x10c100,%eax
  1027df:	00 00 00 
  1027e2:	05 20 bb 10 00       	add    $0x10bb20,%eax
  1027e7:	3d 20 bb 10 00       	cmp    $0x10bb20,%eax
  1027ec:	76 6d                	jbe    10285b <mainc+0x10b>
  1027ee:	bb 20 bb 10 00       	mov    $0x10bb20,%ebx
  1027f3:	90                   	nop
  1027f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if(c == cpus+cpunum())  // We've started already.
  1027f8:	e8 33 fd ff ff       	call   102530 <cpunum>
  1027fd:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
  102803:	05 20 bb 10 00       	add    $0x10bb20,%eax
  102808:	39 d8                	cmp    %ebx,%eax
  10280a:	74 36                	je     102842 <mainc+0xf2>
      continue;

    // Tell bootother.S what stack to use and the address of mpmain;
    // it expects to find these two addresses stored just before
    // its first instruction.
    stack = kalloc();
  10280c:	e8 3f fa ff ff       	call   102250 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
    *(void**)(code-8) = mpmain;
  102811:	c7 05 f8 6f 00 00 e0 	movl   $0x1026e0,0x6ff8
  102818:	26 10 00 

    // Tell bootother.S what stack to use and the address of mpmain;
    // it expects to find these two addresses stored just before
    // its first instruction.
    stack = kalloc();
    *(void**)(code-4) = stack + KSTACKSIZE;
  10281b:	05 00 10 00 00       	add    $0x1000,%eax
  102820:	a3 fc 6f 00 00       	mov    %eax,0x6ffc
    *(void**)(code-8) = mpmain;

    lapicstartap(c->id, (uint)code);
  102825:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
  10282c:	00 
  10282d:	0f b6 03             	movzbl (%ebx),%eax
  102830:	89 04 24             	mov    %eax,(%esp)
  102833:	e8 48 fc ff ff       	call   102480 <lapicstartap>

    // Wait for cpu to finish mpmain()
    while(c->booted == 0)
  102838:	8b 83 a8 00 00 00    	mov    0xa8(%ebx),%eax
  10283e:	85 c0                	test   %eax,%eax
  102840:	74 f6                	je     102838 <mainc+0xe8>
  // The linker has placed the image of bootother.S in
  // _binary_bootother_start.
  code = (uchar*)0x7000;
  memmove(code, _binary_bootother_start, (uint)_binary_bootother_size);

  for(c = cpus; c < cpus+ncpu; c++){
  102842:	69 05 00 c1 10 00 bc 	imul   $0xbc,0x10c100,%eax
  102849:	00 00 00 
  10284c:	81 c3 bc 00 00 00    	add    $0xbc,%ebx
  102852:	05 20 bb 10 00       	add    $0x10bb20,%eax
  102857:	39 c3                	cmp    %eax,%ebx
  102859:	72 9d                	jb     1027f8 <mainc+0xa8>
  userinit();      // first user process
  bootothers();    // start other processors

  // Finish setting up this processor in mpmain.
  mpmain();
}
  10285b:	83 c4 14             	add    $0x14,%esp
  10285e:	5b                   	pop    %ebx
  10285f:	5d                   	pop    %ebp
    timerinit();   // uniprocessor timer
  userinit();      // first user process
  bootothers();    // start other processors

  // Finish setting up this processor in mpmain.
  mpmain();
  102860:	e9 7b fe ff ff       	jmp    1026e0 <mpmain>
  binit();         // buffer cache
  fileinit();      // file table
  iinit();         // inode cache
  ideinit();       // disk
  if(!ismp)
    timerinit();   // uniprocessor timer
  102865:	e8 b6 25 00 00       	call   104e20 <timerinit>
  10286a:	e9 48 ff ff ff       	jmp    1027b7 <mainc+0x67>
  10286f:	90                   	nop

00102870 <jmpkstack>:
  jmpkstack();       // call mainc() on a properly-allocated stack 
}

void
jmpkstack(void)
{
  102870:	55                   	push   %ebp
  102871:	89 e5                	mov    %esp,%ebp
  102873:	83 ec 18             	sub    $0x18,%esp
  char *kstack, *top;
  
  kstack = kalloc();
  102876:	e8 d5 f9 ff ff       	call   102250 <kalloc>
  if(kstack == 0)
  10287b:	85 c0                	test   %eax,%eax
  10287d:	74 19                	je     102898 <jmpkstack+0x28>
    panic("jmpkstack kalloc");
  top = kstack + PGSIZE;
  asm volatile("movl %0,%%esp; call mainc" : : "r" (top));
  10287f:	05 00 10 00 00       	add    $0x1000,%eax
  102884:	89 c4                	mov    %eax,%esp
  102886:	e8 c5 fe ff ff       	call   102750 <mainc>
  panic("jmpkstack");
  10288b:	c7 04 24 49 6a 10 00 	movl   $0x106a49,(%esp)
  102892:	e8 89 e0 ff ff       	call   100920 <panic>
  102897:	90                   	nop
{
  char *kstack, *top;
  
  kstack = kalloc();
  if(kstack == 0)
    panic("jmpkstack kalloc");
  102898:	c7 04 24 38 6a 10 00 	movl   $0x106a38,(%esp)
  10289f:	e8 7c e0 ff ff       	call   100920 <panic>
  1028a4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1028aa:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

001028b0 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
  1028b0:	55                   	push   %ebp
  1028b1:	89 e5                	mov    %esp,%ebp
  1028b3:	83 e4 f0             	and    $0xfffffff0,%esp
  1028b6:	83 ec 10             	sub    $0x10,%esp
  mpinit();        // collect info about this machine
  1028b9:	e8 b2 00 00 00       	call   102970 <mpinit>
  lapicinit(mpbcpu());
  1028be:	e8 1d 00 00 00       	call   1028e0 <mpbcpu>
  1028c3:	89 04 24             	mov    %eax,(%esp)
  1028c6:	e8 b5 fc ff ff       	call   102580 <lapicinit>
  seginit();       // set up segments
  1028cb:	e8 e0 3b 00 00       	call   1064b0 <seginit>
  kinit();         // initialize memory allocator
  1028d0:	e8 2b fa ff ff       	call   102300 <kinit>
  jmpkstack();       // call mainc() on a properly-allocated stack 
  1028d5:	e8 96 ff ff ff       	call   102870 <jmpkstack>
  1028da:	90                   	nop
  1028db:	90                   	nop
  1028dc:	90                   	nop
  1028dd:	90                   	nop
  1028de:	90                   	nop
  1028df:	90                   	nop

001028e0 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
  1028e0:	a1 c4 78 10 00       	mov    0x1078c4,%eax
  1028e5:	55                   	push   %ebp
  1028e6:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
}
  1028e8:	5d                   	pop    %ebp
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
  1028e9:	2d 20 bb 10 00       	sub    $0x10bb20,%eax
  1028ee:	c1 f8 02             	sar    $0x2,%eax
  1028f1:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
  return bcpu-cpus;
}
  1028f7:	c3                   	ret    
  1028f8:	90                   	nop
  1028f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102900 <mpsearch1>:
}

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uchar *addr, int len)
{
  102900:	55                   	push   %ebp
  102901:	89 e5                	mov    %esp,%ebp
  102903:	56                   	push   %esi
  102904:	53                   	push   %ebx
  uchar *e, *p;

  e = addr+len;
  102905:	8d 34 10             	lea    (%eax,%edx,1),%esi
}

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uchar *addr, int len)
{
  102908:	83 ec 10             	sub    $0x10,%esp
  uchar *e, *p;

  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
  10290b:	39 f0                	cmp    %esi,%eax
  10290d:	73 42                	jae    102951 <mpsearch1+0x51>
  10290f:	89 c3                	mov    %eax,%ebx
  102911:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  102918:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  10291f:	00 
  102920:	c7 44 24 04 53 6a 10 	movl   $0x106a53,0x4(%esp)
  102927:	00 
  102928:	89 1c 24             	mov    %ebx,(%esp)
  10292b:	e8 10 14 00 00       	call   103d40 <memcmp>
  102930:	85 c0                	test   %eax,%eax
  102932:	75 16                	jne    10294a <mpsearch1+0x4a>
  102934:	31 d2                	xor    %edx,%edx
  102936:	66 90                	xchg   %ax,%ax
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
    sum += addr[i];
  102938:	0f b6 0c 03          	movzbl (%ebx,%eax,1),%ecx
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
  10293c:	83 c0 01             	add    $0x1,%eax
    sum += addr[i];
  10293f:	01 ca                	add    %ecx,%edx
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
  102941:	83 f8 10             	cmp    $0x10,%eax
  102944:	75 f2                	jne    102938 <mpsearch1+0x38>
{
  uchar *e, *p;

  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  102946:	84 d2                	test   %dl,%dl
  102948:	74 10                	je     10295a <mpsearch1+0x5a>
mpsearch1(uchar *addr, int len)
{
  uchar *e, *p;

  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
  10294a:	83 c3 10             	add    $0x10,%ebx
  10294d:	39 de                	cmp    %ebx,%esi
  10294f:	77 c7                	ja     102918 <mpsearch1+0x18>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
}
  102951:	83 c4 10             	add    $0x10,%esp
mpsearch1(uchar *addr, int len)
{
  uchar *e, *p;

  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
  102954:	31 c0                	xor    %eax,%eax
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
}
  102956:	5b                   	pop    %ebx
  102957:	5e                   	pop    %esi
  102958:	5d                   	pop    %ebp
  102959:	c3                   	ret    
  10295a:	83 c4 10             	add    $0x10,%esp
  uchar *e, *p;

  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  10295d:	89 d8                	mov    %ebx,%eax
  return 0;
}
  10295f:	5b                   	pop    %ebx
  102960:	5e                   	pop    %esi
  102961:	5d                   	pop    %ebp
  102962:	c3                   	ret    
  102963:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102969:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102970 <mpinit>:
  return conf;
}

void
mpinit(void)
{
  102970:	55                   	push   %ebp
  102971:	89 e5                	mov    %esp,%ebp
  102973:	57                   	push   %edi
  102974:	56                   	push   %esi
  102975:	53                   	push   %ebx
  102976:	83 ec 1c             	sub    $0x1c,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar*)0x400;
  if((p = ((bda[0x0F]<<8)|bda[0x0E]) << 4)){
  102979:	0f b6 05 0f 04 00 00 	movzbl 0x40f,%eax
  102980:	0f b6 15 0e 04 00 00 	movzbl 0x40e,%edx
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  102987:	c7 05 c4 78 10 00 20 	movl   $0x10bb20,0x1078c4
  10298e:	bb 10 00 
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar*)0x400;
  if((p = ((bda[0x0F]<<8)|bda[0x0E]) << 4)){
  102991:	c1 e0 08             	shl    $0x8,%eax
  102994:	09 d0                	or     %edx,%eax
  102996:	c1 e0 04             	shl    $0x4,%eax
  102999:	85 c0                	test   %eax,%eax
  10299b:	75 1b                	jne    1029b8 <mpinit+0x48>
    if((mp = mpsearch1((uchar*)p, 1024)))
      return mp;
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1((uchar*)p-1024, 1024)))
  10299d:	0f b6 05 14 04 00 00 	movzbl 0x414,%eax
  1029a4:	0f b6 15 13 04 00 00 	movzbl 0x413,%edx
  1029ab:	c1 e0 08             	shl    $0x8,%eax
  1029ae:	09 d0                	or     %edx,%eax
  1029b0:	c1 e0 0a             	shl    $0xa,%eax
  1029b3:	2d 00 04 00 00       	sub    $0x400,%eax
  1029b8:	ba 00 04 00 00       	mov    $0x400,%edx
  1029bd:	e8 3e ff ff ff       	call   102900 <mpsearch1>
  1029c2:	85 c0                	test   %eax,%eax
  1029c4:	89 c6                	mov    %eax,%esi
  1029c6:	0f 84 94 01 00 00    	je     102b60 <mpinit+0x1f0>
mpconfig(struct mp **pmp)
{
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
  1029cc:	8b 5e 04             	mov    0x4(%esi),%ebx
  1029cf:	85 db                	test   %ebx,%ebx
  1029d1:	74 1c                	je     1029ef <mpinit+0x7f>
    return 0;
  conf = (struct mpconf*)mp->physaddr;
  if(memcmp(conf, "PCMP", 4) != 0)
  1029d3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  1029da:	00 
  1029db:	c7 44 24 04 58 6a 10 	movl   $0x106a58,0x4(%esp)
  1029e2:	00 
  1029e3:	89 1c 24             	mov    %ebx,(%esp)
  1029e6:	e8 55 13 00 00       	call   103d40 <memcmp>
  1029eb:	85 c0                	test   %eax,%eax
  1029ed:	74 09                	je     1029f8 <mpinit+0x88>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
  1029ef:	83 c4 1c             	add    $0x1c,%esp
  1029f2:	5b                   	pop    %ebx
  1029f3:	5e                   	pop    %esi
  1029f4:	5f                   	pop    %edi
  1029f5:	5d                   	pop    %ebp
  1029f6:	c3                   	ret    
  1029f7:	90                   	nop
  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
    return 0;
  conf = (struct mpconf*)mp->physaddr;
  if(memcmp(conf, "PCMP", 4) != 0)
    return 0;
  if(conf->version != 1 && conf->version != 4)
  1029f8:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
  1029fc:	3c 04                	cmp    $0x4,%al
  1029fe:	74 04                	je     102a04 <mpinit+0x94>
  102a00:	3c 01                	cmp    $0x1,%al
  102a02:	75 eb                	jne    1029ef <mpinit+0x7f>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
  102a04:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
  102a08:	85 ff                	test   %edi,%edi
  102a0a:	74 15                	je     102a21 <mpinit+0xb1>
  102a0c:	31 d2                	xor    %edx,%edx
  102a0e:	31 c0                	xor    %eax,%eax
    sum += addr[i];
  102a10:	0f b6 0c 03          	movzbl (%ebx,%eax,1),%ecx
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
  102a14:	83 c0 01             	add    $0x1,%eax
    sum += addr[i];
  102a17:	01 ca                	add    %ecx,%edx
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
  102a19:	39 c7                	cmp    %eax,%edi
  102a1b:	7f f3                	jg     102a10 <mpinit+0xa0>
  conf = (struct mpconf*)mp->physaddr;
  if(memcmp(conf, "PCMP", 4) != 0)
    return 0;
  if(conf->version != 1 && conf->version != 4)
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
  102a1d:	84 d2                	test   %dl,%dl
  102a1f:	75 ce                	jne    1029ef <mpinit+0x7f>
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  102a21:	c7 05 04 bb 10 00 01 	movl   $0x1,0x10bb04
  102a28:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
  102a2b:	8b 43 24             	mov    0x24(%ebx),%eax
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
  102a2e:	8d 7b 2c             	lea    0x2c(%ebx),%edi

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  102a31:	a3 f8 ba 10 00       	mov    %eax,0x10baf8
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
  102a36:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
  102a3a:	01 c3                	add    %eax,%ebx
  102a3c:	39 df                	cmp    %ebx,%edi
  102a3e:	72 29                	jb     102a69 <mpinit+0xf9>
  102a40:	eb 52                	jmp    102a94 <mpinit+0x124>
  102a42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    case MPIOINTR:
    case MPLINTR:
      p += 8;
      continue;
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
  102a48:	0f b6 c0             	movzbl %al,%eax
  102a4b:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a4f:	c7 04 24 78 6a 10 00 	movl   $0x106a78,(%esp)
  102a56:	e8 d5 da ff ff       	call   100530 <cprintf>
      ismp = 0;
  102a5b:	c7 05 04 bb 10 00 00 	movl   $0x0,0x10bb04
  102a62:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
  102a65:	39 fb                	cmp    %edi,%ebx
  102a67:	76 1e                	jbe    102a87 <mpinit+0x117>
    switch(*p){
  102a69:	0f b6 07             	movzbl (%edi),%eax
  102a6c:	3c 04                	cmp    $0x4,%al
  102a6e:	77 d8                	ja     102a48 <mpinit+0xd8>
  102a70:	0f b6 c0             	movzbl %al,%eax
  102a73:	ff 24 85 98 6a 10 00 	jmp    *0x106a98(,%eax,4)
  102a7a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
      p += sizeof(struct mpioapic);
      continue;
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
  102a80:	83 c7 08             	add    $0x8,%edi
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
  102a83:	39 fb                	cmp    %edi,%ebx
  102a85:	77 e2                	ja     102a69 <mpinit+0xf9>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
  102a87:	a1 04 bb 10 00       	mov    0x10bb04,%eax
  102a8c:	85 c0                	test   %eax,%eax
  102a8e:	0f 84 a4 00 00 00    	je     102b38 <mpinit+0x1c8>
    lapic = 0;
    ioapicid = 0;
    return;
  }

  if(mp->imcrp){
  102a94:	80 7e 0c 00          	cmpb   $0x0,0xc(%esi)
  102a98:	0f 84 51 ff ff ff    	je     1029ef <mpinit+0x7f>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  102a9e:	ba 22 00 00 00       	mov    $0x22,%edx
  102aa3:	b8 70 00 00 00       	mov    $0x70,%eax
  102aa8:	ee                   	out    %al,(%dx)
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  102aa9:	b2 23                	mov    $0x23,%dl
  102aab:	ec                   	in     (%dx),%al
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  102aac:	83 c8 01             	or     $0x1,%eax
  102aaf:	ee                   	out    %al,(%dx)
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
  102ab0:	83 c4 1c             	add    $0x1c,%esp
  102ab3:	5b                   	pop    %ebx
  102ab4:	5e                   	pop    %esi
  102ab5:	5f                   	pop    %edi
  102ab6:	5d                   	pop    %ebp
  102ab7:	c3                   	ret    
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu != proc->apicid){
  102ab8:	0f b6 57 01          	movzbl 0x1(%edi),%edx
  102abc:	a1 00 c1 10 00       	mov    0x10c100,%eax
  102ac1:	39 c2                	cmp    %eax,%edx
  102ac3:	74 23                	je     102ae8 <mpinit+0x178>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
  102ac5:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ac9:	89 54 24 08          	mov    %edx,0x8(%esp)
  102acd:	c7 04 24 5d 6a 10 00 	movl   $0x106a5d,(%esp)
  102ad4:	e8 57 da ff ff       	call   100530 <cprintf>
        ismp = 0;
  102ad9:	a1 00 c1 10 00       	mov    0x10c100,%eax
  102ade:	c7 05 04 bb 10 00 00 	movl   $0x0,0x10bb04
  102ae5:	00 00 00 
      }
      if(proc->flags & MPBOOT)
  102ae8:	f6 47 03 02          	testb  $0x2,0x3(%edi)
  102aec:	74 12                	je     102b00 <mpinit+0x190>
        bcpu = &cpus[ncpu];
  102aee:	69 d0 bc 00 00 00    	imul   $0xbc,%eax,%edx
  102af4:	81 c2 20 bb 10 00    	add    $0x10bb20,%edx
  102afa:	89 15 c4 78 10 00    	mov    %edx,0x1078c4
      cpus[ncpu].id = ncpu;
  102b00:	69 d0 bc 00 00 00    	imul   $0xbc,%eax,%edx
      ncpu++;
      p += sizeof(struct mpproc);
  102b06:	83 c7 14             	add    $0x14,%edi
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
        ismp = 0;
      }
      if(proc->flags & MPBOOT)
        bcpu = &cpus[ncpu];
      cpus[ncpu].id = ncpu;
  102b09:	88 82 20 bb 10 00    	mov    %al,0x10bb20(%edx)
      ncpu++;
  102b0f:	83 c0 01             	add    $0x1,%eax
  102b12:	a3 00 c1 10 00       	mov    %eax,0x10c100
      p += sizeof(struct mpproc);
      continue;
  102b17:	e9 49 ff ff ff       	jmp    102a65 <mpinit+0xf5>
  102b1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
  102b20:	0f b6 47 01          	movzbl 0x1(%edi),%eax
      p += sizeof(struct mpioapic);
  102b24:	83 c7 08             	add    $0x8,%edi
      ncpu++;
      p += sizeof(struct mpproc);
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
  102b27:	a2 00 bb 10 00       	mov    %al,0x10bb00
      p += sizeof(struct mpioapic);
      continue;
  102b2c:	e9 34 ff ff ff       	jmp    102a65 <mpinit+0xf5>
  102b31:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
      ismp = 0;
    }
  }
  if(!ismp){
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
  102b38:	c7 05 00 c1 10 00 01 	movl   $0x1,0x10c100
  102b3f:	00 00 00 
    lapic = 0;
  102b42:	c7 05 f8 ba 10 00 00 	movl   $0x0,0x10baf8
  102b49:	00 00 00 
    ioapicid = 0;
  102b4c:	c6 05 00 bb 10 00 00 	movb   $0x0,0x10bb00
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
  102b53:	83 c4 1c             	add    $0x1c,%esp
  102b56:	5b                   	pop    %ebx
  102b57:	5e                   	pop    %esi
  102b58:	5f                   	pop    %edi
  102b59:	5d                   	pop    %ebp
  102b5a:	c3                   	ret    
  102b5b:	90                   	nop
  102b5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1((uchar*)p-1024, 1024)))
      return mp;
  }
  return mpsearch1((uchar*)0xF0000, 0x10000);
  102b60:	ba 00 00 01 00       	mov    $0x10000,%edx
  102b65:	b8 00 00 0f 00       	mov    $0xf0000,%eax
  102b6a:	e8 91 fd ff ff       	call   102900 <mpsearch1>
mpconfig(struct mp **pmp)
{
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
  102b6f:	85 c0                	test   %eax,%eax
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1((uchar*)p-1024, 1024)))
      return mp;
  }
  return mpsearch1((uchar*)0xF0000, 0x10000);
  102b71:	89 c6                	mov    %eax,%esi
mpconfig(struct mp **pmp)
{
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
  102b73:	0f 85 53 fe ff ff    	jne    1029cc <mpinit+0x5c>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
  102b79:	83 c4 1c             	add    $0x1c,%esp
  102b7c:	5b                   	pop    %ebx
  102b7d:	5e                   	pop    %esi
  102b7e:	5f                   	pop    %edi
  102b7f:	5d                   	pop    %ebp
  102b80:	c3                   	ret    
  102b81:	90                   	nop
  102b82:	90                   	nop
  102b83:	90                   	nop
  102b84:	90                   	nop
  102b85:	90                   	nop
  102b86:	90                   	nop
  102b87:	90                   	nop
  102b88:	90                   	nop
  102b89:	90                   	nop
  102b8a:	90                   	nop
  102b8b:	90                   	nop
  102b8c:	90                   	nop
  102b8d:	90                   	nop
  102b8e:	90                   	nop
  102b8f:	90                   	nop

00102b90 <picenable>:
  outb(IO_PIC2+1, mask >> 8);
}

void
picenable(int irq)
{
  102b90:	55                   	push   %ebp
  picsetmask(irqmask & ~(1<<irq));
  102b91:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
  outb(IO_PIC2+1, mask >> 8);
}

void
picenable(int irq)
{
  102b96:	89 e5                	mov    %esp,%ebp
  102b98:	ba 21 00 00 00       	mov    $0x21,%edx
  picsetmask(irqmask & ~(1<<irq));
  102b9d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102ba0:	d3 c0                	rol    %cl,%eax
  102ba2:	66 23 05 20 73 10 00 	and    0x107320,%ax
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
  irqmask = mask;
  102ba9:	66 a3 20 73 10 00    	mov    %ax,0x107320
  102baf:	ee                   	out    %al,(%dx)
  102bb0:	66 c1 e8 08          	shr    $0x8,%ax
  102bb4:	b2 a1                	mov    $0xa1,%dl
  102bb6:	ee                   	out    %al,(%dx)

void
picenable(int irq)
{
  picsetmask(irqmask & ~(1<<irq));
}
  102bb7:	5d                   	pop    %ebp
  102bb8:	c3                   	ret    
  102bb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102bc0 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
  102bc0:	55                   	push   %ebp
  102bc1:	b9 21 00 00 00       	mov    $0x21,%ecx
  102bc6:	89 e5                	mov    %esp,%ebp
  102bc8:	83 ec 0c             	sub    $0xc,%esp
  102bcb:	89 1c 24             	mov    %ebx,(%esp)
  102bce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102bd3:	89 ca                	mov    %ecx,%edx
  102bd5:	89 74 24 04          	mov    %esi,0x4(%esp)
  102bd9:	89 7c 24 08          	mov    %edi,0x8(%esp)
  102bdd:	ee                   	out    %al,(%dx)
  102bde:	bb a1 00 00 00       	mov    $0xa1,%ebx
  102be3:	89 da                	mov    %ebx,%edx
  102be5:	ee                   	out    %al,(%dx)
  102be6:	be 11 00 00 00       	mov    $0x11,%esi
  102beb:	b2 20                	mov    $0x20,%dl
  102bed:	89 f0                	mov    %esi,%eax
  102bef:	ee                   	out    %al,(%dx)
  102bf0:	b8 20 00 00 00       	mov    $0x20,%eax
  102bf5:	89 ca                	mov    %ecx,%edx
  102bf7:	ee                   	out    %al,(%dx)
  102bf8:	b8 04 00 00 00       	mov    $0x4,%eax
  102bfd:	ee                   	out    %al,(%dx)
  102bfe:	bf 03 00 00 00       	mov    $0x3,%edi
  102c03:	89 f8                	mov    %edi,%eax
  102c05:	ee                   	out    %al,(%dx)
  102c06:	b1 a0                	mov    $0xa0,%cl
  102c08:	89 f0                	mov    %esi,%eax
  102c0a:	89 ca                	mov    %ecx,%edx
  102c0c:	ee                   	out    %al,(%dx)
  102c0d:	b8 28 00 00 00       	mov    $0x28,%eax
  102c12:	89 da                	mov    %ebx,%edx
  102c14:	ee                   	out    %al,(%dx)
  102c15:	b8 02 00 00 00       	mov    $0x2,%eax
  102c1a:	ee                   	out    %al,(%dx)
  102c1b:	89 f8                	mov    %edi,%eax
  102c1d:	ee                   	out    %al,(%dx)
  102c1e:	be 68 00 00 00       	mov    $0x68,%esi
  102c23:	b2 20                	mov    $0x20,%dl
  102c25:	89 f0                	mov    %esi,%eax
  102c27:	ee                   	out    %al,(%dx)
  102c28:	bb 0a 00 00 00       	mov    $0xa,%ebx
  102c2d:	89 d8                	mov    %ebx,%eax
  102c2f:	ee                   	out    %al,(%dx)
  102c30:	89 f0                	mov    %esi,%eax
  102c32:	89 ca                	mov    %ecx,%edx
  102c34:	ee                   	out    %al,(%dx)
  102c35:	89 d8                	mov    %ebx,%eax
  102c37:	ee                   	out    %al,(%dx)
  outb(IO_PIC1, 0x0a);             // read IRR by default

  outb(IO_PIC2, 0x68);             // OCW3
  outb(IO_PIC2, 0x0a);             // OCW3

  if(irqmask != 0xFFFF)
  102c38:	0f b7 05 20 73 10 00 	movzwl 0x107320,%eax
  102c3f:	66 83 f8 ff          	cmp    $0xffffffff,%ax
  102c43:	74 0a                	je     102c4f <picinit+0x8f>
  102c45:	b2 21                	mov    $0x21,%dl
  102c47:	ee                   	out    %al,(%dx)
  102c48:	66 c1 e8 08          	shr    $0x8,%ax
  102c4c:	b2 a1                	mov    $0xa1,%dl
  102c4e:	ee                   	out    %al,(%dx)
    picsetmask(irqmask);
}
  102c4f:	8b 1c 24             	mov    (%esp),%ebx
  102c52:	8b 74 24 04          	mov    0x4(%esp),%esi
  102c56:	8b 7c 24 08          	mov    0x8(%esp),%edi
  102c5a:	89 ec                	mov    %ebp,%esp
  102c5c:	5d                   	pop    %ebp
  102c5d:	c3                   	ret    
  102c5e:	90                   	nop
  102c5f:	90                   	nop

00102c60 <piperead>:
  return n;
}

int
piperead(struct pipe *p, char *addr, int n)
{
  102c60:	55                   	push   %ebp
  102c61:	89 e5                	mov    %esp,%ebp
  102c63:	57                   	push   %edi
  102c64:	56                   	push   %esi
  102c65:	53                   	push   %ebx
  102c66:	83 ec 1c             	sub    $0x1c,%esp
  102c69:	8b 5d 08             	mov    0x8(%ebp),%ebx
  102c6c:	8b 7d 10             	mov    0x10(%ebp),%edi
  int i;

  acquire(&p->lock);
  102c6f:	89 1c 24             	mov    %ebx,(%esp)
  102c72:	e8 09 10 00 00       	call   103c80 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
  102c77:	8b 93 34 02 00 00    	mov    0x234(%ebx),%edx
  102c7d:	3b 93 38 02 00 00    	cmp    0x238(%ebx),%edx
  102c83:	75 58                	jne    102cdd <piperead+0x7d>
  102c85:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
  102c8b:	85 f6                	test   %esi,%esi
  102c8d:	74 4e                	je     102cdd <piperead+0x7d>
    if(proc->killed){
  102c8f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  102c95:	8d b3 34 02 00 00    	lea    0x234(%ebx),%esi
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
    if(proc->killed){
  102c9b:	8b 48 24             	mov    0x24(%eax),%ecx
  102c9e:	85 c9                	test   %ecx,%ecx
  102ca0:	74 21                	je     102cc3 <piperead+0x63>
  102ca2:	e9 99 00 00 00       	jmp    102d40 <piperead+0xe0>
  102ca7:	90                   	nop
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
  102ca8:	8b 83 40 02 00 00    	mov    0x240(%ebx),%eax
  102cae:	85 c0                	test   %eax,%eax
  102cb0:	74 2b                	je     102cdd <piperead+0x7d>
    if(proc->killed){
  102cb2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  102cb8:	8b 50 24             	mov    0x24(%eax),%edx
  102cbb:	85 d2                	test   %edx,%edx
  102cbd:	0f 85 7d 00 00 00    	jne    102d40 <piperead+0xe0>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  102cc3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  102cc7:	89 34 24             	mov    %esi,(%esp)
  102cca:	e8 81 05 00 00       	call   103250 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
  102ccf:	8b 93 34 02 00 00    	mov    0x234(%ebx),%edx
  102cd5:	3b 93 38 02 00 00    	cmp    0x238(%ebx),%edx
  102cdb:	74 cb                	je     102ca8 <piperead+0x48>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
  102cdd:	85 ff                	test   %edi,%edi
  102cdf:	7e 76                	jle    102d57 <piperead+0xf7>
    if(p->nread == p->nwrite)
  102ce1:	31 f6                	xor    %esi,%esi
  102ce3:	3b 93 38 02 00 00    	cmp    0x238(%ebx),%edx
  102ce9:	75 0d                	jne    102cf8 <piperead+0x98>
  102ceb:	eb 6a                	jmp    102d57 <piperead+0xf7>
  102ced:	8d 76 00             	lea    0x0(%esi),%esi
  102cf0:	39 93 38 02 00 00    	cmp    %edx,0x238(%ebx)
  102cf6:	74 22                	je     102d1a <piperead+0xba>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  102cf8:	89 d0                	mov    %edx,%eax
  102cfa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  102cfd:	83 c2 01             	add    $0x1,%edx
  102d00:	25 ff 01 00 00       	and    $0x1ff,%eax
  102d05:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
  102d0a:	88 04 31             	mov    %al,(%ecx,%esi,1)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
  102d0d:	83 c6 01             	add    $0x1,%esi
  102d10:	39 f7                	cmp    %esi,%edi
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  102d12:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
  102d18:	7f d6                	jg     102cf0 <piperead+0x90>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
  102d1a:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
  102d20:	89 04 24             	mov    %eax,(%esp)
  102d23:	e8 08 04 00 00       	call   103130 <wakeup>
  release(&p->lock);
  102d28:	89 1c 24             	mov    %ebx,(%esp)
  102d2b:	e8 00 0f 00 00       	call   103c30 <release>
  return i;
}
  102d30:	83 c4 1c             	add    $0x1c,%esp
  102d33:	89 f0                	mov    %esi,%eax
  102d35:	5b                   	pop    %ebx
  102d36:	5e                   	pop    %esi
  102d37:	5f                   	pop    %edi
  102d38:	5d                   	pop    %ebp
  102d39:	c3                   	ret    
  102d3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
    if(proc->killed){
      release(&p->lock);
  102d40:	be ff ff ff ff       	mov    $0xffffffff,%esi
  102d45:	89 1c 24             	mov    %ebx,(%esp)
  102d48:	e8 e3 0e 00 00       	call   103c30 <release>
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
  release(&p->lock);
  return i;
}
  102d4d:	83 c4 1c             	add    $0x1c,%esp
  102d50:	89 f0                	mov    %esi,%eax
  102d52:	5b                   	pop    %ebx
  102d53:	5e                   	pop    %esi
  102d54:	5f                   	pop    %edi
  102d55:	5d                   	pop    %ebp
  102d56:	c3                   	ret    
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
  102d57:	31 f6                	xor    %esi,%esi
  102d59:	eb bf                	jmp    102d1a <piperead+0xba>
  102d5b:	90                   	nop
  102d5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00102d60 <pipewrite>:
    release(&p->lock);
}

int
pipewrite(struct pipe *p, char *addr, int n)
{
  102d60:	55                   	push   %ebp
  102d61:	89 e5                	mov    %esp,%ebp
  102d63:	57                   	push   %edi
  102d64:	56                   	push   %esi
  102d65:	53                   	push   %ebx
  102d66:	83 ec 3c             	sub    $0x3c,%esp
  102d69:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
  102d6c:	89 1c 24             	mov    %ebx,(%esp)
  102d6f:	8d b3 34 02 00 00    	lea    0x234(%ebx),%esi
  102d75:	e8 06 0f 00 00       	call   103c80 <acquire>
  for(i = 0; i < n; i++){
  102d7a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102d7d:	85 c9                	test   %ecx,%ecx
  102d7f:	0f 8e 8d 00 00 00    	jle    102e12 <pipewrite+0xb2>
  102d85:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
      if(p->readopen == 0 || proc->killed){
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
  102d8b:	8d bb 38 02 00 00    	lea    0x238(%ebx),%edi
  102d91:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  102d98:	eb 37                	jmp    102dd1 <pipewrite+0x71>
  102d9a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
  102da0:	8b 83 3c 02 00 00    	mov    0x23c(%ebx),%eax
  102da6:	85 c0                	test   %eax,%eax
  102da8:	74 7e                	je     102e28 <pipewrite+0xc8>
  102daa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  102db0:	8b 50 24             	mov    0x24(%eax),%edx
  102db3:	85 d2                	test   %edx,%edx
  102db5:	75 71                	jne    102e28 <pipewrite+0xc8>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
  102db7:	89 34 24             	mov    %esi,(%esp)
  102dba:	e8 71 03 00 00       	call   103130 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
  102dbf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  102dc3:	89 3c 24             	mov    %edi,(%esp)
  102dc6:	e8 85 04 00 00       	call   103250 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
  102dcb:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
  102dd1:	8b 93 34 02 00 00    	mov    0x234(%ebx),%edx
  102dd7:	81 c2 00 02 00 00    	add    $0x200,%edx
  102ddd:	39 d0                	cmp    %edx,%eax
  102ddf:	74 bf                	je     102da0 <pipewrite+0x40>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  102de1:	89 c2                	mov    %eax,%edx
  102de3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  102de6:	83 c0 01             	add    $0x1,%eax
  102de9:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
  102def:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  102df2:	8b 55 0c             	mov    0xc(%ebp),%edx
  102df5:	0f b6 0c 0a          	movzbl (%edx,%ecx,1),%ecx
  102df9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102dfc:	88 4c 13 34          	mov    %cl,0x34(%ebx,%edx,1)
  102e00:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
  102e06:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  102e0a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  102e0d:	39 4d 10             	cmp    %ecx,0x10(%ebp)
  102e10:	7f bf                	jg     102dd1 <pipewrite+0x71>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  102e12:	89 34 24             	mov    %esi,(%esp)
  102e15:	e8 16 03 00 00       	call   103130 <wakeup>
  release(&p->lock);
  102e1a:	89 1c 24             	mov    %ebx,(%esp)
  102e1d:	e8 0e 0e 00 00       	call   103c30 <release>
  return n;
  102e22:	eb 13                	jmp    102e37 <pipewrite+0xd7>
  102e24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
        release(&p->lock);
  102e28:	89 1c 24             	mov    %ebx,(%esp)
  102e2b:	e8 00 0e 00 00       	call   103c30 <release>
  102e30:	c7 45 10 ff ff ff ff 	movl   $0xffffffff,0x10(%ebp)
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
  102e37:	8b 45 10             	mov    0x10(%ebp),%eax
  102e3a:	83 c4 3c             	add    $0x3c,%esp
  102e3d:	5b                   	pop    %ebx
  102e3e:	5e                   	pop    %esi
  102e3f:	5f                   	pop    %edi
  102e40:	5d                   	pop    %ebp
  102e41:	c3                   	ret    
  102e42:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  102e49:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102e50 <pipeclose>:
  return -1;
}

void
pipeclose(struct pipe *p, int writable)
{
  102e50:	55                   	push   %ebp
  102e51:	89 e5                	mov    %esp,%ebp
  102e53:	83 ec 18             	sub    $0x18,%esp
  102e56:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  102e59:	8b 5d 08             	mov    0x8(%ebp),%ebx
  102e5c:	89 75 fc             	mov    %esi,-0x4(%ebp)
  102e5f:	8b 75 0c             	mov    0xc(%ebp),%esi
  acquire(&p->lock);
  102e62:	89 1c 24             	mov    %ebx,(%esp)
  102e65:	e8 16 0e 00 00       	call   103c80 <acquire>
  if(writable){
  102e6a:	85 f6                	test   %esi,%esi
  102e6c:	74 42                	je     102eb0 <pipeclose+0x60>
    p->writeopen = 0;
    wakeup(&p->nread);
  102e6e:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
void
pipeclose(struct pipe *p, int writable)
{
  acquire(&p->lock);
  if(writable){
    p->writeopen = 0;
  102e74:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
  102e7b:	00 00 00 
    wakeup(&p->nread);
  102e7e:	89 04 24             	mov    %eax,(%esp)
  102e81:	e8 aa 02 00 00       	call   103130 <wakeup>
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
  102e86:	8b 83 3c 02 00 00    	mov    0x23c(%ebx),%eax
  102e8c:	85 c0                	test   %eax,%eax
  102e8e:	75 0a                	jne    102e9a <pipeclose+0x4a>
  102e90:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
  102e96:	85 f6                	test   %esi,%esi
  102e98:	74 36                	je     102ed0 <pipeclose+0x80>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
  102e9a:	89 5d 08             	mov    %ebx,0x8(%ebp)
}
  102e9d:	8b 75 fc             	mov    -0x4(%ebp),%esi
  102ea0:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  102ea3:	89 ec                	mov    %ebp,%esp
  102ea5:	5d                   	pop    %ebp
  }
  if(p->readopen == 0 && p->writeopen == 0){
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
  102ea6:	e9 85 0d 00 00       	jmp    103c30 <release>
  102eab:	90                   	nop
  102eac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  if(writable){
    p->writeopen = 0;
    wakeup(&p->nread);
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  102eb0:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
  acquire(&p->lock);
  if(writable){
    p->writeopen = 0;
    wakeup(&p->nread);
  } else {
    p->readopen = 0;
  102eb6:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
  102ebd:	00 00 00 
    wakeup(&p->nwrite);
  102ec0:	89 04 24             	mov    %eax,(%esp)
  102ec3:	e8 68 02 00 00       	call   103130 <wakeup>
  102ec8:	eb bc                	jmp    102e86 <pipeclose+0x36>
  102eca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  }
  if(p->readopen == 0 && p->writeopen == 0){
    release(&p->lock);
  102ed0:	89 1c 24             	mov    %ebx,(%esp)
  102ed3:	e8 58 0d 00 00       	call   103c30 <release>
    kfree((char*)p);
  } else
    release(&p->lock);
}
  102ed8:	8b 75 fc             	mov    -0x4(%ebp),%esi
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
    release(&p->lock);
    kfree((char*)p);
  102edb:	89 5d 08             	mov    %ebx,0x8(%ebp)
  } else
    release(&p->lock);
}
  102ede:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  102ee1:	89 ec                	mov    %ebp,%esp
  102ee3:	5d                   	pop    %ebp
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
    release(&p->lock);
    kfree((char*)p);
  102ee4:	e9 a7 f3 ff ff       	jmp    102290 <kfree>
  102ee9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00102ef0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
  102ef0:	55                   	push   %ebp
  102ef1:	89 e5                	mov    %esp,%ebp
  102ef3:	57                   	push   %edi
  102ef4:	56                   	push   %esi
  102ef5:	53                   	push   %ebx
  102ef6:	83 ec 1c             	sub    $0x1c,%esp
  102ef9:	8b 75 08             	mov    0x8(%ebp),%esi
  102efc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
  102eff:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  102f05:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
  102f0b:	e8 e0 df ff ff       	call   100ef0 <filealloc>
  102f10:	85 c0                	test   %eax,%eax
  102f12:	89 06                	mov    %eax,(%esi)
  102f14:	0f 84 9c 00 00 00    	je     102fb6 <pipealloc+0xc6>
  102f1a:	e8 d1 df ff ff       	call   100ef0 <filealloc>
  102f1f:	85 c0                	test   %eax,%eax
  102f21:	89 03                	mov    %eax,(%ebx)
  102f23:	0f 84 7f 00 00 00    	je     102fa8 <pipealloc+0xb8>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
  102f29:	e8 22 f3 ff ff       	call   102250 <kalloc>
  102f2e:	85 c0                	test   %eax,%eax
  102f30:	89 c7                	mov    %eax,%edi
  102f32:	74 74                	je     102fa8 <pipealloc+0xb8>
    goto bad;
  p->readopen = 1;
  102f34:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
  102f3b:	00 00 00 
  p->writeopen = 1;
  102f3e:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
  102f45:	00 00 00 
  p->nwrite = 0;
  102f48:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
  102f4f:	00 00 00 
  p->nread = 0;
  102f52:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
  102f59:	00 00 00 
  initlock(&p->lock, "pipe");
  102f5c:	89 04 24             	mov    %eax,(%esp)
  102f5f:	c7 44 24 04 ac 6a 10 	movl   $0x106aac,0x4(%esp)
  102f66:	00 
  102f67:	e8 84 0b 00 00       	call   103af0 <initlock>
  (*f0)->type = FD_PIPE;
  102f6c:	8b 06                	mov    (%esi),%eax
  102f6e:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
  102f74:	8b 06                	mov    (%esi),%eax
  102f76:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
  102f7a:	8b 06                	mov    (%esi),%eax
  102f7c:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
  102f80:	8b 06                	mov    (%esi),%eax
  102f82:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
  102f85:	8b 03                	mov    (%ebx),%eax
  102f87:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
  102f8d:	8b 03                	mov    (%ebx),%eax
  102f8f:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
  102f93:	8b 03                	mov    (%ebx),%eax
  102f95:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
  102f99:	8b 03                	mov    (%ebx),%eax
  102f9b:	89 78 0c             	mov    %edi,0xc(%eax)
  102f9e:	31 c0                	xor    %eax,%eax
  if(*f0)
    fileclose(*f0);
  if(*f1)
    fileclose(*f1);
  return -1;
}
  102fa0:	83 c4 1c             	add    $0x1c,%esp
  102fa3:	5b                   	pop    %ebx
  102fa4:	5e                   	pop    %esi
  102fa5:	5f                   	pop    %edi
  102fa6:	5d                   	pop    %ebp
  102fa7:	c3                   	ret    
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
  102fa8:	8b 06                	mov    (%esi),%eax
  102faa:	85 c0                	test   %eax,%eax
  102fac:	74 08                	je     102fb6 <pipealloc+0xc6>
    fileclose(*f0);
  102fae:	89 04 24             	mov    %eax,(%esp)
  102fb1:	e8 ba df ff ff       	call   100f70 <fileclose>
  if(*f1)
  102fb6:	8b 13                	mov    (%ebx),%edx
  102fb8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102fbd:	85 d2                	test   %edx,%edx
  102fbf:	74 df                	je     102fa0 <pipealloc+0xb0>
    fileclose(*f1);
  102fc1:	89 14 24             	mov    %edx,(%esp)
  102fc4:	e8 a7 df ff ff       	call   100f70 <fileclose>
  102fc9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102fce:	eb d0                	jmp    102fa0 <pipealloc+0xb0>

00102fd0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  102fd0:	55                   	push   %ebp
  102fd1:	89 e5                	mov    %esp,%ebp
  102fd3:	57                   	push   %edi
  102fd4:	56                   	push   %esi
  102fd5:	53                   	push   %ebx

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
  102fd6:	bb 54 c1 10 00       	mov    $0x10c154,%ebx
{
  102fdb:	83 ec 4c             	sub    $0x4c,%esp
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
  102fde:	8d 7d c0             	lea    -0x40(%ebp),%edi
  102fe1:	eb 4b                	jmp    10302e <procdump+0x5e>
  102fe3:	90                   	nop
  102fe4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
  102fe8:	8b 04 85 84 6b 10 00 	mov    0x106b84(,%eax,4),%eax
  102fef:	85 c0                	test   %eax,%eax
  102ff1:	74 47                	je     10303a <procdump+0x6a>
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
  102ff3:	8b 53 10             	mov    0x10(%ebx),%edx
  102ff6:	8d 4b 6c             	lea    0x6c(%ebx),%ecx
  102ff9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  102ffd:	89 44 24 08          	mov    %eax,0x8(%esp)
  103001:	c7 04 24 b5 6a 10 00 	movl   $0x106ab5,(%esp)
  103008:	89 54 24 04          	mov    %edx,0x4(%esp)
  10300c:	e8 1f d5 ff ff       	call   100530 <cprintf>
    if(p->state == SLEEPING){
  103011:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
  103015:	74 31                	je     103048 <procdump+0x78>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  103017:	c7 04 24 36 6a 10 00 	movl   $0x106a36,(%esp)
  10301e:	e8 0d d5 ff ff       	call   100530 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  103023:	83 c3 7c             	add    $0x7c,%ebx
  103026:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
  10302c:	74 5a                	je     103088 <procdump+0xb8>
    if(p->state == UNUSED)
  10302e:	8b 43 0c             	mov    0xc(%ebx),%eax
  103031:	85 c0                	test   %eax,%eax
  103033:	74 ee                	je     103023 <procdump+0x53>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
  103035:	83 f8 05             	cmp    $0x5,%eax
  103038:	76 ae                	jbe    102fe8 <procdump+0x18>
  10303a:	b8 b1 6a 10 00       	mov    $0x106ab1,%eax
  10303f:	eb b2                	jmp    102ff3 <procdump+0x23>
  103041:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
  103048:	8b 43 1c             	mov    0x1c(%ebx),%eax
  10304b:	31 f6                	xor    %esi,%esi
  10304d:	89 7c 24 04          	mov    %edi,0x4(%esp)
  103051:	8b 40 0c             	mov    0xc(%eax),%eax
  103054:	83 c0 08             	add    $0x8,%eax
  103057:	89 04 24             	mov    %eax,(%esp)
  10305a:	e8 b1 0a 00 00       	call   103b10 <getcallerpcs>
  10305f:	90                   	nop
      for(i=0; i<10 && pc[i] != 0; i++)
  103060:	8b 04 b7             	mov    (%edi,%esi,4),%eax
  103063:	85 c0                	test   %eax,%eax
  103065:	74 b0                	je     103017 <procdump+0x47>
  103067:	83 c6 01             	add    $0x1,%esi
        cprintf(" %p", pc[i]);
  10306a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10306e:	c7 04 24 2a 66 10 00 	movl   $0x10662a,(%esp)
  103075:	e8 b6 d4 ff ff       	call   100530 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
  10307a:	83 fe 0a             	cmp    $0xa,%esi
  10307d:	75 e1                	jne    103060 <procdump+0x90>
  10307f:	eb 96                	jmp    103017 <procdump+0x47>
  103081:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
  103088:	83 c4 4c             	add    $0x4c,%esp
  10308b:	5b                   	pop    %ebx
  10308c:	5e                   	pop    %esi
  10308d:	5f                   	pop    %edi
  10308e:	5d                   	pop    %ebp
  10308f:	90                   	nop
  103090:	c3                   	ret    
  103091:	eb 0d                	jmp    1030a0 <kill>
  103093:	90                   	nop
  103094:	90                   	nop
  103095:	90                   	nop
  103096:	90                   	nop
  103097:	90                   	nop
  103098:	90                   	nop
  103099:	90                   	nop
  10309a:	90                   	nop
  10309b:	90                   	nop
  10309c:	90                   	nop
  10309d:	90                   	nop
  10309e:	90                   	nop
  10309f:	90                   	nop

001030a0 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
  1030a0:	55                   	push   %ebp
  1030a1:	89 e5                	mov    %esp,%ebp
  1030a3:	53                   	push   %ebx
  1030a4:	83 ec 14             	sub    $0x14,%esp
  1030a7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
  1030aa:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1030b1:	e8 ca 0b 00 00       	call   103c80 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
  1030b6:	8b 15 64 c1 10 00    	mov    0x10c164,%edx

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
  1030bc:	b8 d0 c1 10 00       	mov    $0x10c1d0,%eax
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
  1030c1:	39 da                	cmp    %ebx,%edx
  1030c3:	75 0d                	jne    1030d2 <kill+0x32>
  1030c5:	eb 60                	jmp    103127 <kill+0x87>
  1030c7:	90                   	nop
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1030c8:	83 c0 7c             	add    $0x7c,%eax
  1030cb:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  1030d0:	74 3e                	je     103110 <kill+0x70>
    if(p->pid == pid){
  1030d2:	8b 50 10             	mov    0x10(%eax),%edx
  1030d5:	39 da                	cmp    %ebx,%edx
  1030d7:	75 ef                	jne    1030c8 <kill+0x28>
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
  1030d9:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
      p->killed = 1;
  1030dd:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
  1030e4:	74 1a                	je     103100 <kill+0x60>
        p->state = RUNNABLE;
      release(&ptable.lock);
  1030e6:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1030ed:	e8 3e 0b 00 00       	call   103c30 <release>
      return 0;
    }
  }
  release(&ptable.lock);
  return -1;
}
  1030f2:	83 c4 14             	add    $0x14,%esp
    if(p->pid == pid){
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
        p->state = RUNNABLE;
      release(&ptable.lock);
  1030f5:	31 c0                	xor    %eax,%eax
      return 0;
    }
  }
  release(&ptable.lock);
  return -1;
}
  1030f7:	5b                   	pop    %ebx
  1030f8:	5d                   	pop    %ebp
  1030f9:	c3                   	ret    
  1030fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
        p->state = RUNNABLE;
  103100:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  103107:	eb dd                	jmp    1030e6 <kill+0x46>
  103109:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
  103110:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103117:	e8 14 0b 00 00       	call   103c30 <release>
  return -1;
}
  10311c:	83 c4 14             	add    $0x14,%esp
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
  10311f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  return -1;
}
  103124:	5b                   	pop    %ebx
  103125:	5d                   	pop    %ebp
  103126:	c3                   	ret    
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
  103127:	b8 54 c1 10 00       	mov    $0x10c154,%eax
  10312c:	eb ab                	jmp    1030d9 <kill+0x39>
  10312e:	66 90                	xchg   %ax,%ax

00103130 <wakeup>:
}

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
  103130:	55                   	push   %ebp
  103131:	89 e5                	mov    %esp,%ebp
  103133:	53                   	push   %ebx
  103134:	83 ec 14             	sub    $0x14,%esp
  103137:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ptable.lock);
  10313a:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103141:	e8 3a 0b 00 00       	call   103c80 <acquire>
      p->state = RUNNABLE;
}

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
  103146:	b8 54 c1 10 00       	mov    $0x10c154,%eax
  10314b:	eb 0d                	jmp    10315a <wakeup+0x2a>
  10314d:	8d 76 00             	lea    0x0(%esi),%esi
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  103150:	83 c0 7c             	add    $0x7c,%eax
  103153:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  103158:	74 1e                	je     103178 <wakeup+0x48>
    if(p->state == SLEEPING && p->chan == chan)
  10315a:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
  10315e:	75 f0                	jne    103150 <wakeup+0x20>
  103160:	3b 58 20             	cmp    0x20(%eax),%ebx
  103163:	75 eb                	jne    103150 <wakeup+0x20>
      p->state = RUNNABLE;
  103165:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  10316c:	83 c0 7c             	add    $0x7c,%eax
  10316f:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  103174:	75 e4                	jne    10315a <wakeup+0x2a>
  103176:	66 90                	xchg   %ax,%ax
void
wakeup(void *chan)
{
  acquire(&ptable.lock);
  wakeup1(chan);
  release(&ptable.lock);
  103178:	c7 45 08 20 c1 10 00 	movl   $0x10c120,0x8(%ebp)
}
  10317f:	83 c4 14             	add    $0x14,%esp
  103182:	5b                   	pop    %ebx
  103183:	5d                   	pop    %ebp
void
wakeup(void *chan)
{
  acquire(&ptable.lock);
  wakeup1(chan);
  release(&ptable.lock);
  103184:	e9 a7 0a 00 00       	jmp    103c30 <release>
  103189:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00103190 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
  103190:	55                   	push   %ebp
  103191:	89 e5                	mov    %esp,%ebp
  103193:	83 ec 18             	sub    $0x18,%esp
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
  103196:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10319d:	e8 8e 0a 00 00       	call   103c30 <release>
  
  // Return to "caller", actually trapret (see allocproc).
}
  1031a2:	c9                   	leave  
  1031a3:	c3                   	ret    
  1031a4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1031aa:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

001031b0 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
  1031b0:	55                   	push   %ebp
  1031b1:	89 e5                	mov    %esp,%ebp
  1031b3:	53                   	push   %ebx
  1031b4:	83 ec 14             	sub    $0x14,%esp
  int intena;

  if(!holding(&ptable.lock))
  1031b7:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1031be:	e8 ad 09 00 00       	call   103b70 <holding>
  1031c3:	85 c0                	test   %eax,%eax
  1031c5:	74 4d                	je     103214 <sched+0x64>
    panic("sched ptable.lock");
  if(cpu->ncli != 1)
  1031c7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  1031cd:	83 b8 ac 00 00 00 01 	cmpl   $0x1,0xac(%eax)
  1031d4:	75 62                	jne    103238 <sched+0x88>
    panic("sched locks");
  if(proc->state == RUNNING)
  1031d6:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1031dd:	83 7a 0c 04          	cmpl   $0x4,0xc(%edx)
  1031e1:	74 49                	je     10322c <sched+0x7c>

static inline uint
readeflags(void)
{
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
  1031e3:	9c                   	pushf  
  1031e4:	59                   	pop    %ecx
    panic("sched running");
  if(readeflags()&FL_IF)
  1031e5:	80 e5 02             	and    $0x2,%ch
  1031e8:	75 36                	jne    103220 <sched+0x70>
    panic("sched interruptible");
  intena = cpu->intena;
  1031ea:	8b 98 b0 00 00 00    	mov    0xb0(%eax),%ebx
  swtch(&proc->context, cpu->scheduler);
  1031f0:	83 c2 1c             	add    $0x1c,%edx
  1031f3:	8b 40 04             	mov    0x4(%eax),%eax
  1031f6:	89 14 24             	mov    %edx,(%esp)
  1031f9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1031fd:	e8 1a 0d 00 00       	call   103f1c <swtch>
  cpu->intena = intena;
  103202:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  103208:	89 98 b0 00 00 00    	mov    %ebx,0xb0(%eax)
}
  10320e:	83 c4 14             	add    $0x14,%esp
  103211:	5b                   	pop    %ebx
  103212:	5d                   	pop    %ebp
  103213:	c3                   	ret    
sched(void)
{
  int intena;

  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
  103214:	c7 04 24 be 6a 10 00 	movl   $0x106abe,(%esp)
  10321b:	e8 00 d7 ff ff       	call   100920 <panic>
  if(cpu->ncli != 1)
    panic("sched locks");
  if(proc->state == RUNNING)
    panic("sched running");
  if(readeflags()&FL_IF)
    panic("sched interruptible");
  103220:	c7 04 24 ea 6a 10 00 	movl   $0x106aea,(%esp)
  103227:	e8 f4 d6 ff ff       	call   100920 <panic>
  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
  if(cpu->ncli != 1)
    panic("sched locks");
  if(proc->state == RUNNING)
    panic("sched running");
  10322c:	c7 04 24 dc 6a 10 00 	movl   $0x106adc,(%esp)
  103233:	e8 e8 d6 ff ff       	call   100920 <panic>
  int intena;

  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
  if(cpu->ncli != 1)
    panic("sched locks");
  103238:	c7 04 24 d0 6a 10 00 	movl   $0x106ad0,(%esp)
  10323f:	e8 dc d6 ff ff       	call   100920 <panic>
  103244:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  10324a:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00103250 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  103250:	55                   	push   %ebp
  103251:	89 e5                	mov    %esp,%ebp
  103253:	56                   	push   %esi
  103254:	53                   	push   %ebx
  103255:	83 ec 10             	sub    $0x10,%esp
  if(proc == 0)
  103258:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  10325e:	8b 75 08             	mov    0x8(%ebp),%esi
  103261:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  if(proc == 0)
  103264:	85 c0                	test   %eax,%eax
  103266:	0f 84 a1 00 00 00    	je     10330d <sleep+0xbd>
    panic("sleep");

  if(lk == 0)
  10326c:	85 db                	test   %ebx,%ebx
  10326e:	0f 84 8d 00 00 00    	je     103301 <sleep+0xb1>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
  103274:	81 fb 20 c1 10 00    	cmp    $0x10c120,%ebx
  10327a:	74 5c                	je     1032d8 <sleep+0x88>
    acquire(&ptable.lock);  //DOC: sleeplock1
  10327c:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103283:	e8 f8 09 00 00       	call   103c80 <acquire>
    release(lk);
  103288:	89 1c 24             	mov    %ebx,(%esp)
  10328b:	e8 a0 09 00 00       	call   103c30 <release>
  }

  // Go to sleep.
  proc->chan = chan;
  103290:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103296:	89 70 20             	mov    %esi,0x20(%eax)
  proc->state = SLEEPING;
  103299:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  10329f:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
  1032a6:	e8 05 ff ff ff       	call   1031b0 <sched>

  // Tidy up.
  proc->chan = 0;
  1032ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1032b1:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
  1032b8:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1032bf:	e8 6c 09 00 00       	call   103c30 <release>
    acquire(lk);
  1032c4:	89 5d 08             	mov    %ebx,0x8(%ebp)
  }
}
  1032c7:	83 c4 10             	add    $0x10,%esp
  1032ca:	5b                   	pop    %ebx
  1032cb:	5e                   	pop    %esi
  1032cc:	5d                   	pop    %ebp
  proc->chan = 0;

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
    acquire(lk);
  1032cd:	e9 ae 09 00 00       	jmp    103c80 <acquire>
  1032d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    acquire(&ptable.lock);  //DOC: sleeplock1
    release(lk);
  }

  // Go to sleep.
  proc->chan = chan;
  1032d8:	89 70 20             	mov    %esi,0x20(%eax)
  proc->state = SLEEPING;
  1032db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1032e1:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
  1032e8:	e8 c3 fe ff ff       	call   1031b0 <sched>

  // Tidy up.
  proc->chan = 0;
  1032ed:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1032f3:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
    acquire(lk);
  }
}
  1032fa:	83 c4 10             	add    $0x10,%esp
  1032fd:	5b                   	pop    %ebx
  1032fe:	5e                   	pop    %esi
  1032ff:	5d                   	pop    %ebp
  103300:	c3                   	ret    
{
  if(proc == 0)
    panic("sleep");

  if(lk == 0)
    panic("sleep without lk");
  103301:	c7 04 24 04 6b 10 00 	movl   $0x106b04,(%esp)
  103308:	e8 13 d6 ff ff       	call   100920 <panic>
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  if(proc == 0)
    panic("sleep");
  10330d:	c7 04 24 fe 6a 10 00 	movl   $0x106afe,(%esp)
  103314:	e8 07 d6 ff ff       	call   100920 <panic>
  103319:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00103320 <yield>:
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  103320:	55                   	push   %ebp
  103321:	89 e5                	mov    %esp,%ebp
  103323:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
  103326:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10332d:	e8 4e 09 00 00       	call   103c80 <acquire>
  proc->state = RUNNABLE;
  103332:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103338:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
  10333f:	e8 6c fe ff ff       	call   1031b0 <sched>
  release(&ptable.lock);
  103344:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10334b:	e8 e0 08 00 00       	call   103c30 <release>
}
  103350:	c9                   	leave  
  103351:	c3                   	ret    
  103352:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  103359:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103360 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
  103360:	55                   	push   %ebp
  103361:	89 e5                	mov    %esp,%ebp
  103363:	53                   	push   %ebx
  103364:	83 ec 14             	sub    $0x14,%esp
  103367:	90                   	nop
}

static inline void
sti(void)
{
  asm volatile("sti");
  103368:	fb                   	sti    
//  - choose a process to run
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
  103369:	bb 54 c1 10 00       	mov    $0x10c154,%ebx
  for(;;){
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
  10336e:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103375:	e8 06 09 00 00       	call   103c80 <acquire>
  10337a:	eb 0f                	jmp    10338b <scheduler+0x2b>
  10337c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  103380:	83 c3 7c             	add    $0x7c,%ebx
  103383:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
  103389:	74 5d                	je     1033e8 <scheduler+0x88>
      if(p->state != RUNNABLE)
  10338b:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
  10338f:	90                   	nop
  103390:	75 ee                	jne    103380 <scheduler+0x20>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
  103392:	65 89 1d 04 00 00 00 	mov    %ebx,%gs:0x4
      switchuvm(p);
  103399:	89 1c 24             	mov    %ebx,(%esp)
  10339c:	e8 5f 30 00 00       	call   106400 <switchuvm>
      p->state = RUNNING;
      swtch(&cpu->scheduler, proc->context);
  1033a1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
      switchuvm(p);
      p->state = RUNNING;
  1033a7:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1033ae:	83 c3 7c             	add    $0x7c,%ebx
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
      switchuvm(p);
      p->state = RUNNING;
      swtch(&cpu->scheduler, proc->context);
  1033b1:	8b 40 1c             	mov    0x1c(%eax),%eax
  1033b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033b8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  1033be:	83 c0 04             	add    $0x4,%eax
  1033c1:	89 04 24             	mov    %eax,(%esp)
  1033c4:	e8 53 0b 00 00       	call   103f1c <swtch>
      switchkvm();
  1033c9:	e8 c2 29 00 00       	call   105d90 <switchkvm>
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1033ce:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
      swtch(&cpu->scheduler, proc->context);
      switchkvm();

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
  1033d4:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
  1033db:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1033df:	75 aa                	jne    10338b <scheduler+0x2b>
  1033e1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
  1033e8:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1033ef:	e8 3c 08 00 00       	call   103c30 <release>

  }
  1033f4:	e9 6f ff ff ff       	jmp    103368 <scheduler+0x8>
  1033f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00103400 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
  103400:	55                   	push   %ebp
  103401:	89 e5                	mov    %esp,%ebp
  103403:	53                   	push   %ebx
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
  103404:	bb 54 c1 10 00       	mov    $0x10c154,%ebx

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
  103409:	83 ec 24             	sub    $0x24,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
  10340c:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103413:	e8 68 08 00 00       	call   103c80 <acquire>
  103418:	31 c0                	xor    %eax,%eax
  10341a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  103420:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
  103426:	72 30                	jb     103458 <wait+0x58>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
  103428:	85 c0                	test   %eax,%eax
  10342a:	74 5c                	je     103488 <wait+0x88>
  10342c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103432:	8b 50 24             	mov    0x24(%eax),%edx
  103435:	85 d2                	test   %edx,%edx
  103437:	75 4f                	jne    103488 <wait+0x88>
      release(&ptable.lock);
      return -1;
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
  103439:	bb 54 c1 10 00       	mov    $0x10c154,%ebx
  10343e:	89 04 24             	mov    %eax,(%esp)
  103441:	c7 44 24 04 20 c1 10 	movl   $0x10c120,0x4(%esp)
  103448:	00 
  103449:	e8 02 fe ff ff       	call   103250 <sleep>
  10344e:	31 c0                	xor    %eax,%eax

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  103450:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
  103456:	73 d0                	jae    103428 <wait+0x28>
      if(p->parent != proc)
  103458:	8b 53 14             	mov    0x14(%ebx),%edx
  10345b:	65 3b 15 04 00 00 00 	cmp    %gs:0x4,%edx
  103462:	74 0c                	je     103470 <wait+0x70>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  103464:	83 c3 7c             	add    $0x7c,%ebx
  103467:	eb b7                	jmp    103420 <wait+0x20>
  103469:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
      if(p->parent != proc)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
  103470:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
  103474:	74 29                	je     10349f <wait+0x9f>
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
        release(&ptable.lock);
        return pid;
  103476:	b8 01 00 00 00       	mov    $0x1,%eax
  10347b:	90                   	nop
  10347c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103480:	eb e2                	jmp    103464 <wait+0x64>
  103482:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
      release(&ptable.lock);
  103488:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10348f:	e8 9c 07 00 00       	call   103c30 <release>
  103494:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
  }
}
  103499:	83 c4 24             	add    $0x24,%esp
  10349c:	5b                   	pop    %ebx
  10349d:	5d                   	pop    %ebp
  10349e:	c3                   	ret    
      if(p->parent != proc)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
        pid = p->pid;
  10349f:	8b 43 10             	mov    0x10(%ebx),%eax
        kfree(p->kstack);
  1034a2:	8b 53 08             	mov    0x8(%ebx),%edx
  1034a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1034a8:	89 14 24             	mov    %edx,(%esp)
  1034ab:	e8 e0 ed ff ff       	call   102290 <kfree>
        p->kstack = 0;
        freevm(p->pgdir);
  1034b0:	8b 53 04             	mov    0x4(%ebx),%edx
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
        pid = p->pid;
        kfree(p->kstack);
        p->kstack = 0;
  1034b3:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
  1034ba:	89 14 24             	mov    %edx,(%esp)
  1034bd:	e8 6e 2c 00 00       	call   106130 <freevm>
        p->state = UNUSED;
  1034c2:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        p->pid = 0;
  1034c9:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
  1034d0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
  1034d7:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
  1034db:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        release(&ptable.lock);
  1034e2:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1034e9:	e8 42 07 00 00       	call   103c30 <release>
        return pid;
  1034ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1034f1:	eb a6                	jmp    103499 <wait+0x99>
  1034f3:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1034f9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103500 <exit>:
  return pid;
}

void
exit(void)
{
  103500:	55                   	push   %ebp
  103501:	89 e5                	mov    %esp,%ebp
  103503:	56                   	push   %esi
  103504:	53                   	push   %ebx
  struct proc *p;
  int fd;

  if(proc == initproc)
    panic("init exiting");
  103505:	31 db                	xor    %ebx,%ebx
  return pid;
}

void
exit(void)
{
  103507:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
  10350a:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  103511:	3b 15 c8 78 10 00    	cmp    0x1078c8,%edx
  103517:	0f 84 fe 00 00 00    	je     10361b <exit+0x11b>
  10351d:	8d 76 00             	lea    0x0(%esi),%esi
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd]){
  103520:	8d 73 08             	lea    0x8(%ebx),%esi
  103523:	8b 44 b2 08          	mov    0x8(%edx,%esi,4),%eax
  103527:	85 c0                	test   %eax,%eax
  103529:	74 1d                	je     103548 <exit+0x48>
      fileclose(proc->ofile[fd]);
  10352b:	89 04 24             	mov    %eax,(%esp)
  10352e:	e8 3d da ff ff       	call   100f70 <fileclose>
      proc->ofile[fd] = 0;
  103533:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103539:	c7 44 b0 08 00 00 00 	movl   $0x0,0x8(%eax,%esi,4)
  103540:	00 
  103541:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
  103548:	83 c3 01             	add    $0x1,%ebx
  10354b:	83 fb 10             	cmp    $0x10,%ebx
  10354e:	75 d0                	jne    103520 <exit+0x20>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
  103550:	8b 42 68             	mov    0x68(%edx),%eax
  103553:	89 04 24             	mov    %eax,(%esp)
  103556:	e8 25 e3 ff ff       	call   101880 <iput>
  proc->cwd = 0;
  10355b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103561:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
  103568:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10356f:	e8 0c 07 00 00       	call   103c80 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
  103574:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
  safestrcpy(np->name, proc->name, sizeof(proc->name));
  return pid;
}

void
exit(void)
  10357b:	b9 54 e0 10 00       	mov    $0x10e054,%ecx
  103580:	b8 54 c1 10 00       	mov    $0x10c154,%eax
  proc->cwd = 0;

  acquire(&ptable.lock);

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
  103585:	8b 53 14             	mov    0x14(%ebx),%edx
  103588:	eb 10                	jmp    10359a <exit+0x9a>
  10358a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  103590:	83 c0 7c             	add    $0x7c,%eax
  103593:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  103598:	74 1c                	je     1035b6 <exit+0xb6>
    if(p->state == SLEEPING && p->chan == chan)
  10359a:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
  10359e:	75 f0                	jne    103590 <exit+0x90>
  1035a0:	3b 50 20             	cmp    0x20(%eax),%edx
  1035a3:	75 eb                	jne    103590 <exit+0x90>
      p->state = RUNNABLE;
  1035a5:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  1035ac:	83 c0 7c             	add    $0x7c,%eax
  1035af:	3d 54 e0 10 00       	cmp    $0x10e054,%eax
  1035b4:	75 e4                	jne    10359a <exit+0x9a>
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->parent == proc){
      p->parent = initproc;
  1035b6:	8b 35 c8 78 10 00    	mov    0x1078c8,%esi
  1035bc:	ba 54 c1 10 00       	mov    $0x10c154,%edx
  1035c1:	eb 10                	jmp    1035d3 <exit+0xd3>
  1035c3:	90                   	nop
  1035c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  1035c8:	83 c2 7c             	add    $0x7c,%edx
  1035cb:	81 fa 54 e0 10 00    	cmp    $0x10e054,%edx
  1035d1:	74 30                	je     103603 <exit+0x103>
    if(p->parent == proc){
  1035d3:	3b 5a 14             	cmp    0x14(%edx),%ebx
  1035d6:	75 f0                	jne    1035c8 <exit+0xc8>
      p->parent = initproc;
      if(p->state == ZOMBIE)
  1035d8:	83 7a 0c 05          	cmpl   $0x5,0xc(%edx)
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->parent == proc){
      p->parent = initproc;
  1035dc:	89 72 14             	mov    %esi,0x14(%edx)
      if(p->state == ZOMBIE)
  1035df:	75 e7                	jne    1035c8 <exit+0xc8>
  1035e1:	b8 54 c1 10 00       	mov    $0x10c154,%eax
  1035e6:	eb 07                	jmp    1035ef <exit+0xef>
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  1035e8:	83 c0 7c             	add    $0x7c,%eax
  1035eb:	39 c1                	cmp    %eax,%ecx
  1035ed:	74 d9                	je     1035c8 <exit+0xc8>
    if(p->state == SLEEPING && p->chan == chan)
  1035ef:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
  1035f3:	75 f3                	jne    1035e8 <exit+0xe8>
  1035f5:	3b 70 20             	cmp    0x20(%eax),%esi
  1035f8:	75 ee                	jne    1035e8 <exit+0xe8>
      p->state = RUNNABLE;
  1035fa:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  103601:	eb e5                	jmp    1035e8 <exit+0xe8>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
  103603:	c7 43 0c 05 00 00 00 	movl   $0x5,0xc(%ebx)
  sched();
  10360a:	e8 a1 fb ff ff       	call   1031b0 <sched>
  panic("zombie exit");
  10360f:	c7 04 24 22 6b 10 00 	movl   $0x106b22,(%esp)
  103616:	e8 05 d3 ff ff       	call   100920 <panic>
{
  struct proc *p;
  int fd;

  if(proc == initproc)
    panic("init exiting");
  10361b:	c7 04 24 15 6b 10 00 	movl   $0x106b15,(%esp)
  103622:	e8 f9 d2 ff ff       	call   100920 <panic>
  103627:	89 f6                	mov    %esi,%esi
  103629:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103630 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
  103630:	55                   	push   %ebp
  103631:	89 e5                	mov    %esp,%ebp
  103633:	53                   	push   %ebx
  103634:	83 ec 14             	sub    $0x14,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  103637:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  10363e:	e8 3d 06 00 00       	call   103c80 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
  103643:	8b 1d 60 c1 10 00    	mov    0x10c160,%ebx
  103649:	85 db                	test   %ebx,%ebx
  10364b:	0f 84 a5 00 00 00    	je     1036f6 <allocproc+0xc6>
// Look in the process table for an UNUSED proc.
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
  103651:	bb d0 c1 10 00       	mov    $0x10c1d0,%ebx
  103656:	eb 0b                	jmp    103663 <allocproc+0x33>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  103658:	83 c3 7c             	add    $0x7c,%ebx
  10365b:	81 fb 54 e0 10 00    	cmp    $0x10e054,%ebx
  103661:	74 7d                	je     1036e0 <allocproc+0xb0>
    if(p->state == UNUSED)
  103663:	8b 4b 0c             	mov    0xc(%ebx),%ecx
  103666:	85 c9                	test   %ecx,%ecx
  103668:	75 ee                	jne    103658 <allocproc+0x28>
      goto found;
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
  10366a:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
  103671:	a1 24 73 10 00       	mov    0x107324,%eax
  103676:	89 43 10             	mov    %eax,0x10(%ebx)
  103679:	83 c0 01             	add    $0x1,%eax
  10367c:	a3 24 73 10 00       	mov    %eax,0x107324
  release(&ptable.lock);
  103681:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103688:	e8 a3 05 00 00       	call   103c30 <release>

  // Allocate kernel stack if possible.
  if((p->kstack = kalloc()) == 0){
  10368d:	e8 be eb ff ff       	call   102250 <kalloc>
  103692:	85 c0                	test   %eax,%eax
  103694:	89 43 08             	mov    %eax,0x8(%ebx)
  103697:	74 67                	je     103700 <allocproc+0xd0>
    return 0;
  }
  sp = p->kstack + KSTACKSIZE;
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
  103699:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
  10369f:	89 53 18             	mov    %edx,0x18(%ebx)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
  *(uint*)sp = (uint)trapret;
  1036a2:	c7 80 b0 0f 00 00 70 	movl   $0x104e70,0xfb0(%eax)
  1036a9:	4e 10 00 

  sp -= sizeof *p->context;
  p->context = (struct context*)sp;
  1036ac:	05 9c 0f 00 00       	add    $0xf9c,%eax
  1036b1:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
  1036b4:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
  1036bb:	00 
  1036bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1036c3:	00 
  1036c4:	89 04 24             	mov    %eax,(%esp)
  1036c7:	e8 54 06 00 00       	call   103d20 <memset>
  p->context->eip = (uint)forkret;
  1036cc:	8b 43 1c             	mov    0x1c(%ebx),%eax
  1036cf:	c7 40 10 90 31 10 00 	movl   $0x103190,0x10(%eax)

  return p;
}
  1036d6:	89 d8                	mov    %ebx,%eax
  1036d8:	83 c4 14             	add    $0x14,%esp
  1036db:	5b                   	pop    %ebx
  1036dc:	5d                   	pop    %ebp
  1036dd:	c3                   	ret    
  1036de:	66 90                	xchg   %ax,%ax

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
  1036e0:	31 db                	xor    %ebx,%ebx
  1036e2:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  1036e9:	e8 42 05 00 00       	call   103c30 <release>
  p->context = (struct context*)sp;
  memset(p->context, 0, sizeof *p->context);
  p->context->eip = (uint)forkret;

  return p;
}
  1036ee:	89 d8                	mov    %ebx,%eax
  1036f0:	83 c4 14             	add    $0x14,%esp
  1036f3:	5b                   	pop    %ebx
  1036f4:	5d                   	pop    %ebp
  1036f5:	c3                   	ret    
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
  return 0;
  1036f6:	bb 54 c1 10 00       	mov    $0x10c154,%ebx
  1036fb:	e9 6a ff ff ff       	jmp    10366a <allocproc+0x3a>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack if possible.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
  103700:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  103707:	31 db                	xor    %ebx,%ebx
    return 0;
  103709:	eb cb                	jmp    1036d6 <allocproc+0xa6>
  10370b:	90                   	nop
  10370c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00103710 <clone>:
  return pid;
}

int
clone(void)
{
  103710:	55                   	push   %ebp
  103711:	89 e5                	mov    %esp,%ebp
  103713:	57                   	push   %edi
  103714:	56                   	push   %esi
  int i, pid, size;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
  103715:	be ff ff ff ff       	mov    $0xffffffff,%esi
  return pid;
}

int
clone(void)
{
  10371a:	53                   	push   %ebx
  10371b:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid, size;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
  10371e:	e8 0d ff ff ff       	call   103630 <allocproc>
  103723:	85 c0                	test   %eax,%eax
  103725:	89 c3                	mov    %eax,%ebx
  103727:	0f 84 fe 00 00 00    	je     10382b <clone+0x11b>
    //kfree(np->kstack);
    //np->kstack = 0;
    //np->state = UNUSED;
    //return -1;
  //}
  np->pgdir = proc->pgdir;
  10372d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  //This might be an issue later.
  np->sz = proc->sz;
  np->parent = proc;
  *np->tf = *proc->tf;
  103733:	b9 13 00 00 00       	mov    $0x13,%ecx
    //kfree(np->kstack);
    //np->kstack = 0;
    //np->state = UNUSED;
    //return -1;
  //}
  np->pgdir = proc->pgdir;
  103738:	8b 40 04             	mov    0x4(%eax),%eax
  10373b:	89 43 04             	mov    %eax,0x4(%ebx)
  //This might be an issue later.
  np->sz = proc->sz;
  10373e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103744:	8b 00                	mov    (%eax),%eax
  103746:	89 03                	mov    %eax,(%ebx)
  np->parent = proc;
  103748:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  10374e:	89 43 14             	mov    %eax,0x14(%ebx)
  *np->tf = *proc->tf;
  103751:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  103758:	8b 43 18             	mov    0x18(%ebx),%eax
  10375b:	8b 72 18             	mov    0x18(%edx),%esi
  10375e:	89 c7                	mov    %eax,%edi
  103760:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  if(argint(1, &size) < 0 || size <= 0 || argptr(0, &np->kstack, size) < 0) {
  103762:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  103765:	89 44 24 04          	mov    %eax,0x4(%esp)
  103769:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103770:	e8 4b 08 00 00       	call   103fc0 <argint>
  103775:	85 c0                	test   %eax,%eax
  103777:	0f 88 b8 00 00 00    	js     103835 <clone+0x125>
  10377d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103780:	85 c0                	test   %eax,%eax
  103782:	0f 8e ad 00 00 00    	jle    103835 <clone+0x125>
  103788:	89 44 24 08          	mov    %eax,0x8(%esp)
  10378c:	8d 43 08             	lea    0x8(%ebx),%eax
  10378f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103793:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10379a:	e8 61 08 00 00       	call   104000 <argptr>
  10379f:	85 c0                	test   %eax,%eax
  1037a1:	0f 88 8e 00 00 00    	js     103835 <clone+0x125>
    np->state = UNUSED;
    return -1;
  }

  // Clear %eax so that clone returns 0 in the child.
  np->tf->eax = 0;
  1037a7:	8b 43 18             	mov    0x18(%ebx),%eax
  np->kstack = (void *)proc->tf->eip;
  1037aa:	31 f6                	xor    %esi,%esi
    np->state = UNUSED;
    return -1;
  }

  // Clear %eax so that clone returns 0 in the child.
  np->tf->eax = 0;
  1037ac:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  np->kstack = (void *)proc->tf->eip;
  1037b3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1037b9:	8b 40 18             	mov    0x18(%eax),%eax
  1037bc:	8b 40 38             	mov    0x38(%eax),%eax
  1037bf:	89 43 08             	mov    %eax,0x8(%ebx)
  1037c2:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1037c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
  1037d0:	8b 44 b2 28          	mov    0x28(%edx,%esi,4),%eax
  1037d4:	85 c0                	test   %eax,%eax
  1037d6:	74 13                	je     1037eb <clone+0xdb>
      np->ofile[i] = filedup(proc->ofile[i]);
  1037d8:	89 04 24             	mov    %eax,(%esp)
  1037db:	e8 c0 d6 ff ff       	call   100ea0 <filedup>
  1037e0:	89 44 b3 28          	mov    %eax,0x28(%ebx,%esi,4)
  1037e4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx

  // Clear %eax so that clone returns 0 in the child.
  np->tf->eax = 0;
  np->kstack = (void *)proc->tf->eip;

  for(i = 0; i < NOFILE; i++)
  1037eb:	83 c6 01             	add    $0x1,%esi
  1037ee:	83 fe 10             	cmp    $0x10,%esi
  1037f1:	75 dd                	jne    1037d0 <clone+0xc0>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
  1037f3:	8b 42 68             	mov    0x68(%edx),%eax
  1037f6:	89 04 24             	mov    %eax,(%esp)
  1037f9:	e8 a2 d8 ff ff       	call   1010a0 <idup>

  pid = np->pid;
  1037fe:	8b 73 10             	mov    0x10(%ebx),%esi
  np->state = RUNNABLE;
  103801:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  np->kstack = (void *)proc->tf->eip;

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
  103808:	89 43 68             	mov    %eax,0x68(%ebx)

  pid = np->pid;
  np->state = RUNNABLE;
  safestrcpy(np->name, proc->name, sizeof(proc->name));
  10380b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103811:	83 c3 6c             	add    $0x6c,%ebx
  103814:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  10381b:	00 
  10381c:	89 1c 24             	mov    %ebx,(%esp)
  10381f:	83 c0 6c             	add    $0x6c,%eax
  103822:	89 44 24 04          	mov    %eax,0x4(%esp)
  103826:	e8 95 06 00 00       	call   103ec0 <safestrcpy>
  return pid;
}
  10382b:	83 c4 2c             	add    $0x2c,%esp
  10382e:	89 f0                	mov    %esi,%eax
  103830:	5b                   	pop    %ebx
  103831:	5e                   	pop    %esi
  103832:	5f                   	pop    %edi
  103833:	5d                   	pop    %ebp
  103834:	c3                   	ret    
  np->sz = proc->sz;
  np->parent = proc;
  *np->tf = *proc->tf;

  if(argint(1, &size) < 0 || size <= 0 || argptr(0, &np->kstack, size) < 0) {
    kfree(np->kstack);
  103835:	8b 43 08             	mov    0x8(%ebx),%eax
    np->kstack = 0;
    np->state = UNUSED;
  103838:	be ff ff ff ff       	mov    $0xffffffff,%esi
  np->sz = proc->sz;
  np->parent = proc;
  *np->tf = *proc->tf;

  if(argint(1, &size) < 0 || size <= 0 || argptr(0, &np->kstack, size) < 0) {
    kfree(np->kstack);
  10383d:	89 04 24             	mov    %eax,(%esp)
  103840:	e8 4b ea ff ff       	call   102290 <kfree>
    np->kstack = 0;
  103845:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
  10384c:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
  103853:	eb d6                	jmp    10382b <clone+0x11b>
  103855:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103859:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103860 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
  103860:	55                   	push   %ebp
  103861:	89 e5                	mov    %esp,%ebp
  103863:	57                   	push   %edi
  103864:	56                   	push   %esi
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
  103865:	be ff ff ff ff       	mov    $0xffffffff,%esi
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
  10386a:	53                   	push   %ebx
  10386b:	83 ec 1c             	sub    $0x1c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
  10386e:	e8 bd fd ff ff       	call   103630 <allocproc>
  103873:	85 c0                	test   %eax,%eax
  103875:	89 c3                	mov    %eax,%ebx
  103877:	0f 84 be 00 00 00    	je     10393b <fork+0xdb>
    return -1;

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
  10387d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103883:	8b 10                	mov    (%eax),%edx
  103885:	89 54 24 04          	mov    %edx,0x4(%esp)
  103889:	8b 40 04             	mov    0x4(%eax),%eax
  10388c:	89 04 24             	mov    %eax,(%esp)
  10388f:	e8 1c 29 00 00       	call   1061b0 <copyuvm>
  103894:	85 c0                	test   %eax,%eax
  103896:	89 43 04             	mov    %eax,0x4(%ebx)
  103899:	0f 84 a6 00 00 00    	je     103945 <fork+0xe5>
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = proc->sz;
  10389f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  np->parent = proc;
  *np->tf = *proc->tf;
  1038a5:	b9 13 00 00 00       	mov    $0x13,%ecx
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = proc->sz;
  1038aa:	8b 00                	mov    (%eax),%eax
  1038ac:	89 03                	mov    %eax,(%ebx)
  np->parent = proc;
  1038ae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1038b4:	89 43 14             	mov    %eax,0x14(%ebx)
  *np->tf = *proc->tf;
  1038b7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1038be:	8b 43 18             	mov    0x18(%ebx),%eax
  1038c1:	8b 72 18             	mov    0x18(%edx),%esi
  1038c4:	89 c7                	mov    %eax,%edi
  1038c6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
  1038c8:	31 f6                	xor    %esi,%esi
  1038ca:	8b 43 18             	mov    0x18(%ebx),%eax
  1038cd:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  1038d4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1038db:	90                   	nop
  1038dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
  1038e0:	8b 44 b2 28          	mov    0x28(%edx,%esi,4),%eax
  1038e4:	85 c0                	test   %eax,%eax
  1038e6:	74 13                	je     1038fb <fork+0x9b>
      np->ofile[i] = filedup(proc->ofile[i]);
  1038e8:	89 04 24             	mov    %eax,(%esp)
  1038eb:	e8 b0 d5 ff ff       	call   100ea0 <filedup>
  1038f0:	89 44 b3 28          	mov    %eax,0x28(%ebx,%esi,4)
  1038f4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
  1038fb:	83 c6 01             	add    $0x1,%esi
  1038fe:	83 fe 10             	cmp    $0x10,%esi
  103901:	75 dd                	jne    1038e0 <fork+0x80>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
  103903:	8b 42 68             	mov    0x68(%edx),%eax
  103906:	89 04 24             	mov    %eax,(%esp)
  103909:	e8 92 d7 ff ff       	call   1010a0 <idup>
 
  pid = np->pid;
  10390e:	8b 73 10             	mov    0x10(%ebx),%esi
  np->state = RUNNABLE;
  103911:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
  103918:	89 43 68             	mov    %eax,0x68(%ebx)
 
  pid = np->pid;
  np->state = RUNNABLE;
  safestrcpy(np->name, proc->name, sizeof(proc->name));
  10391b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103921:	83 c3 6c             	add    $0x6c,%ebx
  103924:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  10392b:	00 
  10392c:	89 1c 24             	mov    %ebx,(%esp)
  10392f:	83 c0 6c             	add    $0x6c,%eax
  103932:	89 44 24 04          	mov    %eax,0x4(%esp)
  103936:	e8 85 05 00 00       	call   103ec0 <safestrcpy>
  return pid;
}
  10393b:	83 c4 1c             	add    $0x1c,%esp
  10393e:	89 f0                	mov    %esi,%eax
  103940:	5b                   	pop    %ebx
  103941:	5e                   	pop    %esi
  103942:	5f                   	pop    %edi
  103943:	5d                   	pop    %ebp
  103944:	c3                   	ret    
  if((np = allocproc()) == 0)
    return -1;

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
    kfree(np->kstack);
  103945:	8b 43 08             	mov    0x8(%ebx),%eax
  103948:	89 04 24             	mov    %eax,(%esp)
  10394b:	e8 40 e9 ff ff       	call   102290 <kfree>
    np->kstack = 0;
  103950:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
  103957:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
  10395e:	eb db                	jmp    10393b <fork+0xdb>

00103960 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  103960:	55                   	push   %ebp
  103961:	89 e5                	mov    %esp,%ebp
  103963:	83 ec 18             	sub    $0x18,%esp
  uint sz;
  
  sz = proc->sz;
  103966:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  10396d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  uint sz;
  
  sz = proc->sz;
  103970:	8b 02                	mov    (%edx),%eax
  if(n > 0){
  103972:	83 f9 00             	cmp    $0x0,%ecx
  103975:	7f 19                	jg     103990 <growproc+0x30>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  } else if(n < 0){
  103977:	75 39                	jne    1039b2 <growproc+0x52>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  proc->sz = sz;
  103979:	89 02                	mov    %eax,(%edx)
  switchuvm(proc);
  10397b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  103981:	89 04 24             	mov    %eax,(%esp)
  103984:	e8 77 2a 00 00       	call   106400 <switchuvm>
  103989:	31 c0                	xor    %eax,%eax
  return 0;
}
  10398b:	c9                   	leave  
  10398c:	c3                   	ret    
  10398d:	8d 76 00             	lea    0x0(%esi),%esi
{
  uint sz;
  
  sz = proc->sz;
  if(n > 0){
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
  103990:	01 c1                	add    %eax,%ecx
  103992:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  103996:	89 44 24 04          	mov    %eax,0x4(%esp)
  10399a:	8b 42 04             	mov    0x4(%edx),%eax
  10399d:	89 04 24             	mov    %eax,(%esp)
  1039a0:	e8 cb 28 00 00       	call   106270 <allocuvm>
  1039a5:	85 c0                	test   %eax,%eax
  1039a7:	74 27                	je     1039d0 <growproc+0x70>
      return -1;
  } else if(n < 0){
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
  1039a9:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1039b0:	eb c7                	jmp    103979 <growproc+0x19>
  1039b2:	01 c1                	add    %eax,%ecx
  1039b4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1039b8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1039bc:	8b 42 04             	mov    0x4(%edx),%eax
  1039bf:	89 04 24             	mov    %eax,(%esp)
  1039c2:	e8 d9 26 00 00       	call   1060a0 <deallocuvm>
  1039c7:	85 c0                	test   %eax,%eax
  1039c9:	75 de                	jne    1039a9 <growproc+0x49>
  1039cb:	90                   	nop
  1039cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
      return -1;
  }
  proc->sz = sz;
  switchuvm(proc);
  return 0;
  1039d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  1039d5:	c9                   	leave  
  1039d6:	c3                   	ret    
  1039d7:	89 f6                	mov    %esi,%esi
  1039d9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001039e0 <userinit>:
}

// Set up first user process.
void
userinit(void)
{
  1039e0:	55                   	push   %ebp
  1039e1:	89 e5                	mov    %esp,%ebp
  1039e3:	53                   	push   %ebx
  1039e4:	83 ec 14             	sub    $0x14,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
  1039e7:	e8 44 fc ff ff       	call   103630 <allocproc>
  1039ec:	89 c3                	mov    %eax,%ebx
  initproc = p;
  1039ee:	a3 c8 78 10 00       	mov    %eax,0x1078c8
  if((p->pgdir = setupkvm()) == 0)
  1039f3:	e8 78 25 00 00       	call   105f70 <setupkvm>
  1039f8:	85 c0                	test   %eax,%eax
  1039fa:	89 43 04             	mov    %eax,0x4(%ebx)
  1039fd:	0f 84 b6 00 00 00    	je     103ab9 <userinit+0xd9>
    panic("userinit: out of memory?");
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
  103a03:	89 04 24             	mov    %eax,(%esp)
  103a06:	c7 44 24 08 2c 00 00 	movl   $0x2c,0x8(%esp)
  103a0d:	00 
  103a0e:	c7 44 24 04 70 77 10 	movl   $0x107770,0x4(%esp)
  103a15:	00 
  103a16:	e8 f5 25 00 00       	call   106010 <inituvm>
  p->sz = PGSIZE;
  103a1b:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
  103a21:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  103a28:	00 
  103a29:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103a30:	00 
  103a31:	8b 43 18             	mov    0x18(%ebx),%eax
  103a34:	89 04 24             	mov    %eax,(%esp)
  103a37:	e8 e4 02 00 00       	call   103d20 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
  103a3c:	8b 43 18             	mov    0x18(%ebx),%eax
  103a3f:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
  103a45:	8b 43 18             	mov    0x18(%ebx),%eax
  103a48:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
  103a4e:	8b 43 18             	mov    0x18(%ebx),%eax
  103a51:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
  103a55:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
  103a59:	8b 43 18             	mov    0x18(%ebx),%eax
  103a5c:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
  103a60:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
  103a64:	8b 43 18             	mov    0x18(%ebx),%eax
  103a67:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
  103a6e:	8b 43 18             	mov    0x18(%ebx),%eax
  103a71:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
  103a78:	8b 43 18             	mov    0x18(%ebx),%eax
  103a7b:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
  103a82:	8d 43 6c             	lea    0x6c(%ebx),%eax
  103a85:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  103a8c:	00 
  103a8d:	c7 44 24 04 47 6b 10 	movl   $0x106b47,0x4(%esp)
  103a94:	00 
  103a95:	89 04 24             	mov    %eax,(%esp)
  103a98:	e8 23 04 00 00       	call   103ec0 <safestrcpy>
  p->cwd = namei("/");
  103a9d:	c7 04 24 50 6b 10 00 	movl   $0x106b50,(%esp)
  103aa4:	e8 a7 e3 ff ff       	call   101e50 <namei>

  p->state = RUNNABLE;
  103aa9:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  p->tf->eflags = FL_IF;
  p->tf->esp = PGSIZE;
  p->tf->eip = 0;  // beginning of initcode.S

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
  103ab0:	89 43 68             	mov    %eax,0x68(%ebx)

  p->state = RUNNABLE;
}
  103ab3:	83 c4 14             	add    $0x14,%esp
  103ab6:	5b                   	pop    %ebx
  103ab7:	5d                   	pop    %ebp
  103ab8:	c3                   	ret    
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
  initproc = p;
  if((p->pgdir = setupkvm()) == 0)
    panic("userinit: out of memory?");
  103ab9:	c7 04 24 2e 6b 10 00 	movl   $0x106b2e,(%esp)
  103ac0:	e8 5b ce ff ff       	call   100920 <panic>
  103ac5:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103ac9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103ad0 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
  103ad0:	55                   	push   %ebp
  103ad1:	89 e5                	mov    %esp,%ebp
  103ad3:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
  103ad6:	c7 44 24 04 52 6b 10 	movl   $0x106b52,0x4(%esp)
  103add:	00 
  103ade:	c7 04 24 20 c1 10 00 	movl   $0x10c120,(%esp)
  103ae5:	e8 06 00 00 00       	call   103af0 <initlock>
}
  103aea:	c9                   	leave  
  103aeb:	c3                   	ret    
  103aec:	90                   	nop
  103aed:	90                   	nop
  103aee:	90                   	nop
  103aef:	90                   	nop

00103af0 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
  103af0:	55                   	push   %ebp
  103af1:	89 e5                	mov    %esp,%ebp
  103af3:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
  103af6:	8b 55 0c             	mov    0xc(%ebp),%edx
  lk->locked = 0;
  103af9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
  lk->name = name;
  103aff:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
  lk->cpu = 0;
  103b02:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
  103b09:	5d                   	pop    %ebp
  103b0a:	c3                   	ret    
  103b0b:	90                   	nop
  103b0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00103b10 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
  103b10:	55                   	push   %ebp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  103b11:	31 c0                	xor    %eax,%eax
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
  103b13:	89 e5                	mov    %esp,%ebp
  103b15:	53                   	push   %ebx
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  103b16:	8b 55 08             	mov    0x8(%ebp),%edx
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
  103b19:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  103b1c:	83 ea 08             	sub    $0x8,%edx
  103b1f:	90                   	nop
  for(i = 0; i < 10; i++){
    if(ebp == 0 || ebp < (uint*)0x100000 || ebp == (uint*)0xffffffff)
  103b20:	8d 8a 00 00 f0 ff    	lea    -0x100000(%edx),%ecx
  103b26:	81 f9 fe ff ef ff    	cmp    $0xffeffffe,%ecx
  103b2c:	77 1a                	ja     103b48 <getcallerpcs+0x38>
      break;
    pcs[i] = ebp[1];     // saved %eip
  103b2e:	8b 4a 04             	mov    0x4(%edx),%ecx
  103b31:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
  103b34:	83 c0 01             	add    $0x1,%eax
    if(ebp == 0 || ebp < (uint*)0x100000 || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  103b37:	8b 12                	mov    (%edx),%edx
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
  103b39:	83 f8 0a             	cmp    $0xa,%eax
  103b3c:	75 e2                	jne    103b20 <getcallerpcs+0x10>
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
    pcs[i] = 0;
}
  103b3e:	5b                   	pop    %ebx
  103b3f:	5d                   	pop    %ebp
  103b40:	c3                   	ret    
  103b41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    if(ebp == 0 || ebp < (uint*)0x100000 || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
  103b48:	83 f8 09             	cmp    $0x9,%eax
  103b4b:	7f f1                	jg     103b3e <getcallerpcs+0x2e>
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
    if(ebp == 0 || ebp < (uint*)0x100000 || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  103b4d:	8d 14 83             	lea    (%ebx,%eax,4),%edx
  }
  for(; i < 10; i++)
  103b50:	83 c0 01             	add    $0x1,%eax
    pcs[i] = 0;
  103b53:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
    if(ebp == 0 || ebp < (uint*)0x100000 || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
  103b59:	83 c2 04             	add    $0x4,%edx
  103b5c:	83 f8 0a             	cmp    $0xa,%eax
  103b5f:	75 ef                	jne    103b50 <getcallerpcs+0x40>
    pcs[i] = 0;
}
  103b61:	5b                   	pop    %ebx
  103b62:	5d                   	pop    %ebp
  103b63:	c3                   	ret    
  103b64:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  103b6a:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00103b70 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
  103b70:	55                   	push   %ebp
  return lock->locked && lock->cpu == cpu;
  103b71:	31 c0                	xor    %eax,%eax
}

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
  103b73:	89 e5                	mov    %esp,%ebp
  103b75:	8b 55 08             	mov    0x8(%ebp),%edx
  return lock->locked && lock->cpu == cpu;
  103b78:	8b 0a                	mov    (%edx),%ecx
  103b7a:	85 c9                	test   %ecx,%ecx
  103b7c:	74 10                	je     103b8e <holding+0x1e>
  103b7e:	8b 42 08             	mov    0x8(%edx),%eax
  103b81:	65 3b 05 00 00 00 00 	cmp    %gs:0x0,%eax
  103b88:	0f 94 c0             	sete   %al
  103b8b:	0f b6 c0             	movzbl %al,%eax
}
  103b8e:	5d                   	pop    %ebp
  103b8f:	c3                   	ret    

00103b90 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
  103b90:	55                   	push   %ebp
  103b91:	89 e5                	mov    %esp,%ebp
  103b93:	53                   	push   %ebx

static inline uint
readeflags(void)
{
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
  103b94:	9c                   	pushf  
  103b95:	5b                   	pop    %ebx
}

static inline void
cli(void)
{
  asm volatile("cli");
  103b96:	fa                   	cli    
  int eflags;
  
  eflags = readeflags();
  cli();
  if(cpu->ncli++ == 0)
  103b97:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
  103b9e:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
  103ba4:	8d 48 01             	lea    0x1(%eax),%ecx
  103ba7:	85 c0                	test   %eax,%eax
  103ba9:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
  103baf:	75 12                	jne    103bc3 <pushcli+0x33>
    cpu->intena = eflags & FL_IF;
  103bb1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  103bb7:	81 e3 00 02 00 00    	and    $0x200,%ebx
  103bbd:	89 98 b0 00 00 00    	mov    %ebx,0xb0(%eax)
}
  103bc3:	5b                   	pop    %ebx
  103bc4:	5d                   	pop    %ebp
  103bc5:	c3                   	ret    
  103bc6:	8d 76 00             	lea    0x0(%esi),%esi
  103bc9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103bd0 <popcli>:

void
popcli(void)
{
  103bd0:	55                   	push   %ebp
  103bd1:	89 e5                	mov    %esp,%ebp
  103bd3:	83 ec 18             	sub    $0x18,%esp

static inline uint
readeflags(void)
{
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
  103bd6:	9c                   	pushf  
  103bd7:	58                   	pop    %eax
  if(readeflags()&FL_IF)
  103bd8:	f6 c4 02             	test   $0x2,%ah
  103bdb:	75 43                	jne    103c20 <popcli+0x50>
    panic("popcli - interruptible");
  if(--cpu->ncli < 0)
  103bdd:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
  103be4:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
  103bea:	83 e8 01             	sub    $0x1,%eax
  103bed:	85 c0                	test   %eax,%eax
  103bef:	89 82 ac 00 00 00    	mov    %eax,0xac(%edx)
  103bf5:	78 1d                	js     103c14 <popcli+0x44>
    panic("popcli");
  if(cpu->ncli == 0 && cpu->intena)
  103bf7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  103bfd:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
  103c03:	85 d2                	test   %edx,%edx
  103c05:	75 0b                	jne    103c12 <popcli+0x42>
  103c07:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  103c0d:	85 c0                	test   %eax,%eax
  103c0f:	74 01                	je     103c12 <popcli+0x42>
}

static inline void
sti(void)
{
  asm volatile("sti");
  103c11:	fb                   	sti    
    sti();
}
  103c12:	c9                   	leave  
  103c13:	c3                   	ret    
popcli(void)
{
  if(readeflags()&FL_IF)
    panic("popcli - interruptible");
  if(--cpu->ncli < 0)
    panic("popcli");
  103c14:	c7 04 24 b3 6b 10 00 	movl   $0x106bb3,(%esp)
  103c1b:	e8 00 cd ff ff       	call   100920 <panic>

void
popcli(void)
{
  if(readeflags()&FL_IF)
    panic("popcli - interruptible");
  103c20:	c7 04 24 9c 6b 10 00 	movl   $0x106b9c,(%esp)
  103c27:	e8 f4 cc ff ff       	call   100920 <panic>
  103c2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00103c30 <release>:
}

// Release the lock.
void
release(struct spinlock *lk)
{
  103c30:	55                   	push   %ebp
  103c31:	89 e5                	mov    %esp,%ebp
  103c33:	83 ec 18             	sub    $0x18,%esp
  103c36:	8b 55 08             	mov    0x8(%ebp),%edx

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
  return lock->locked && lock->cpu == cpu;
  103c39:	8b 0a                	mov    (%edx),%ecx
  103c3b:	85 c9                	test   %ecx,%ecx
  103c3d:	74 0c                	je     103c4b <release+0x1b>
  103c3f:	8b 42 08             	mov    0x8(%edx),%eax
  103c42:	65 3b 05 00 00 00 00 	cmp    %gs:0x0,%eax
  103c49:	74 0d                	je     103c58 <release+0x28>
// Release the lock.
void
release(struct spinlock *lk)
{
  if(!holding(lk))
    panic("release");
  103c4b:	c7 04 24 ba 6b 10 00 	movl   $0x106bba,(%esp)
  103c52:	e8 c9 cc ff ff       	call   100920 <panic>
  103c57:	90                   	nop

  lk->pcs[0] = 0;
  103c58:	c7 42 0c 00 00 00 00 	movl   $0x0,0xc(%edx)
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
  103c5f:	31 c0                	xor    %eax,%eax
  lk->cpu = 0;
  103c61:	c7 42 08 00 00 00 00 	movl   $0x0,0x8(%edx)
  103c68:	f0 87 02             	lock xchg %eax,(%edx)
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);

  popcli();
}
  103c6b:	c9                   	leave  
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);

  popcli();
  103c6c:	e9 5f ff ff ff       	jmp    103bd0 <popcli>
  103c71:	eb 0d                	jmp    103c80 <acquire>
  103c73:	90                   	nop
  103c74:	90                   	nop
  103c75:	90                   	nop
  103c76:	90                   	nop
  103c77:	90                   	nop
  103c78:	90                   	nop
  103c79:	90                   	nop
  103c7a:	90                   	nop
  103c7b:	90                   	nop
  103c7c:	90                   	nop
  103c7d:	90                   	nop
  103c7e:	90                   	nop
  103c7f:	90                   	nop

00103c80 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
  103c80:	55                   	push   %ebp
  103c81:	89 e5                	mov    %esp,%ebp
  103c83:	53                   	push   %ebx
  103c84:	83 ec 14             	sub    $0x14,%esp

static inline uint
readeflags(void)
{
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
  103c87:	9c                   	pushf  
  103c88:	5b                   	pop    %ebx
}

static inline void
cli(void)
{
  asm volatile("cli");
  103c89:	fa                   	cli    
{
  int eflags;
  
  eflags = readeflags();
  cli();
  if(cpu->ncli++ == 0)
  103c8a:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
  103c91:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
  103c97:	8d 48 01             	lea    0x1(%eax),%ecx
  103c9a:	85 c0                	test   %eax,%eax
  103c9c:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
  103ca2:	75 12                	jne    103cb6 <acquire+0x36>
    cpu->intena = eflags & FL_IF;
  103ca4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  103caa:	81 e3 00 02 00 00    	and    $0x200,%ebx
  103cb0:	89 98 b0 00 00 00    	mov    %ebx,0xb0(%eax)
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
  pushcli(); // disable interrupts to avoid deadlock.
  if(holding(lk))
  103cb6:	8b 55 08             	mov    0x8(%ebp),%edx

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
  return lock->locked && lock->cpu == cpu;
  103cb9:	8b 1a                	mov    (%edx),%ebx
  103cbb:	85 db                	test   %ebx,%ebx
  103cbd:	74 0c                	je     103ccb <acquire+0x4b>
  103cbf:	8b 42 08             	mov    0x8(%edx),%eax
  103cc2:	65 3b 05 00 00 00 00 	cmp    %gs:0x0,%eax
  103cc9:	74 45                	je     103d10 <acquire+0x90>
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
  103ccb:	b9 01 00 00 00       	mov    $0x1,%ecx
  103cd0:	eb 09                	jmp    103cdb <acquire+0x5b>
  103cd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    panic("acquire");

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
  103cd8:	8b 55 08             	mov    0x8(%ebp),%edx
  103cdb:	89 c8                	mov    %ecx,%eax
  103cdd:	f0 87 02             	lock xchg %eax,(%edx)
  103ce0:	85 c0                	test   %eax,%eax
  103ce2:	75 f4                	jne    103cd8 <acquire+0x58>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
  103ce4:	8b 45 08             	mov    0x8(%ebp),%eax
  103ce7:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
  103cee:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
  103cf1:	8b 45 08             	mov    0x8(%ebp),%eax
  103cf4:	83 c0 0c             	add    $0xc,%eax
  103cf7:	89 44 24 04          	mov    %eax,0x4(%esp)
  103cfb:	8d 45 08             	lea    0x8(%ebp),%eax
  103cfe:	89 04 24             	mov    %eax,(%esp)
  103d01:	e8 0a fe ff ff       	call   103b10 <getcallerpcs>
}
  103d06:	83 c4 14             	add    $0x14,%esp
  103d09:	5b                   	pop    %ebx
  103d0a:	5d                   	pop    %ebp
  103d0b:	c3                   	ret    
  103d0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
void
acquire(struct spinlock *lk)
{
  pushcli(); // disable interrupts to avoid deadlock.
  if(holding(lk))
    panic("acquire");
  103d10:	c7 04 24 c2 6b 10 00 	movl   $0x106bc2,(%esp)
  103d17:	e8 04 cc ff ff       	call   100920 <panic>
  103d1c:	90                   	nop
  103d1d:	90                   	nop
  103d1e:	90                   	nop
  103d1f:	90                   	nop

00103d20 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
  103d20:	55                   	push   %ebp
  103d21:	89 e5                	mov    %esp,%ebp
  103d23:	8b 55 08             	mov    0x8(%ebp),%edx
  103d26:	57                   	push   %edi
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
  103d27:	8b 4d 10             	mov    0x10(%ebp),%ecx
  103d2a:	8b 45 0c             	mov    0xc(%ebp),%eax
  103d2d:	89 d7                	mov    %edx,%edi
  103d2f:	fc                   	cld    
  103d30:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
  103d32:	89 d0                	mov    %edx,%eax
  103d34:	5f                   	pop    %edi
  103d35:	5d                   	pop    %ebp
  103d36:	c3                   	ret    
  103d37:	89 f6                	mov    %esi,%esi
  103d39:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103d40 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
  103d40:	55                   	push   %ebp
  103d41:	89 e5                	mov    %esp,%ebp
  103d43:	57                   	push   %edi
  103d44:	56                   	push   %esi
  103d45:	53                   	push   %ebx
  103d46:	8b 55 10             	mov    0x10(%ebp),%edx
  103d49:	8b 75 08             	mov    0x8(%ebp),%esi
  103d4c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
  103d4f:	85 d2                	test   %edx,%edx
  103d51:	74 2d                	je     103d80 <memcmp+0x40>
    if(*s1 != *s2)
  103d53:	0f b6 1e             	movzbl (%esi),%ebx
  103d56:	0f b6 0f             	movzbl (%edi),%ecx
  103d59:	38 cb                	cmp    %cl,%bl
  103d5b:	75 2b                	jne    103d88 <memcmp+0x48>
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
  103d5d:	83 ea 01             	sub    $0x1,%edx
  103d60:	31 c0                	xor    %eax,%eax
  103d62:	eb 18                	jmp    103d7c <memcmp+0x3c>
  103d64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if(*s1 != *s2)
  103d68:	0f b6 5c 06 01       	movzbl 0x1(%esi,%eax,1),%ebx
  103d6d:	83 ea 01             	sub    $0x1,%edx
  103d70:	0f b6 4c 07 01       	movzbl 0x1(%edi,%eax,1),%ecx
  103d75:	83 c0 01             	add    $0x1,%eax
  103d78:	38 cb                	cmp    %cl,%bl
  103d7a:	75 0c                	jne    103d88 <memcmp+0x48>
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
  103d7c:	85 d2                	test   %edx,%edx
  103d7e:	75 e8                	jne    103d68 <memcmp+0x28>
  103d80:	31 c0                	xor    %eax,%eax
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
}
  103d82:	5b                   	pop    %ebx
  103d83:	5e                   	pop    %esi
  103d84:	5f                   	pop    %edi
  103d85:	5d                   	pop    %ebp
  103d86:	c3                   	ret    
  103d87:	90                   	nop
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    if(*s1 != *s2)
      return *s1 - *s2;
  103d88:	0f b6 c3             	movzbl %bl,%eax
  103d8b:	0f b6 c9             	movzbl %cl,%ecx
  103d8e:	29 c8                	sub    %ecx,%eax
    s1++, s2++;
  }

  return 0;
}
  103d90:	5b                   	pop    %ebx
  103d91:	5e                   	pop    %esi
  103d92:	5f                   	pop    %edi
  103d93:	5d                   	pop    %ebp
  103d94:	c3                   	ret    
  103d95:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103d99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103da0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
  103da0:	55                   	push   %ebp
  103da1:	89 e5                	mov    %esp,%ebp
  103da3:	57                   	push   %edi
  103da4:	56                   	push   %esi
  103da5:	53                   	push   %ebx
  103da6:	8b 45 08             	mov    0x8(%ebp),%eax
  103da9:	8b 75 0c             	mov    0xc(%ebp),%esi
  103dac:	8b 5d 10             	mov    0x10(%ebp),%ebx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
  103daf:	39 c6                	cmp    %eax,%esi
  103db1:	73 2d                	jae    103de0 <memmove+0x40>
  103db3:	8d 3c 1e             	lea    (%esi,%ebx,1),%edi
  103db6:	39 f8                	cmp    %edi,%eax
  103db8:	73 26                	jae    103de0 <memmove+0x40>
    s += n;
    d += n;
    while(n-- > 0)
  103dba:	85 db                	test   %ebx,%ebx
  103dbc:	74 1d                	je     103ddb <memmove+0x3b>

  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
  103dbe:	8d 34 18             	lea    (%eax,%ebx,1),%esi
  103dc1:	31 d2                	xor    %edx,%edx
  103dc3:	90                   	nop
  103dc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    while(n-- > 0)
      *--d = *--s;
  103dc8:	0f b6 4c 17 ff       	movzbl -0x1(%edi,%edx,1),%ecx
  103dcd:	88 4c 16 ff          	mov    %cl,-0x1(%esi,%edx,1)
  103dd1:	83 ea 01             	sub    $0x1,%edx
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
  103dd4:	8d 0c 1a             	lea    (%edx,%ebx,1),%ecx
  103dd7:	85 c9                	test   %ecx,%ecx
  103dd9:	75 ed                	jne    103dc8 <memmove+0x28>
  } else
    while(n-- > 0)
      *d++ = *s++;

  return dst;
}
  103ddb:	5b                   	pop    %ebx
  103ddc:	5e                   	pop    %esi
  103ddd:	5f                   	pop    %edi
  103dde:	5d                   	pop    %ebp
  103ddf:	c3                   	ret    
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
  103de0:	31 d2                	xor    %edx,%edx
      *--d = *--s;
  } else
    while(n-- > 0)
  103de2:	85 db                	test   %ebx,%ebx
  103de4:	74 f5                	je     103ddb <memmove+0x3b>
  103de6:	66 90                	xchg   %ax,%ax
      *d++ = *s++;
  103de8:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  103dec:	88 0c 10             	mov    %cl,(%eax,%edx,1)
  103def:	83 c2 01             	add    $0x1,%edx
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
  103df2:	39 d3                	cmp    %edx,%ebx
  103df4:	75 f2                	jne    103de8 <memmove+0x48>
      *d++ = *s++;

  return dst;
}
  103df6:	5b                   	pop    %ebx
  103df7:	5e                   	pop    %esi
  103df8:	5f                   	pop    %edi
  103df9:	5d                   	pop    %ebp
  103dfa:	c3                   	ret    
  103dfb:	90                   	nop
  103dfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00103e00 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
  103e00:	55                   	push   %ebp
  103e01:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
}
  103e03:	5d                   	pop    %ebp

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
  return memmove(dst, src, n);
  103e04:	e9 97 ff ff ff       	jmp    103da0 <memmove>
  103e09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00103e10 <strncmp>:
}

int
strncmp(const char *p, const char *q, uint n)
{
  103e10:	55                   	push   %ebp
  103e11:	89 e5                	mov    %esp,%ebp
  103e13:	57                   	push   %edi
  103e14:	56                   	push   %esi
  103e15:	53                   	push   %ebx
  103e16:	8b 7d 10             	mov    0x10(%ebp),%edi
  103e19:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103e1c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  while(n > 0 && *p && *p == *q)
  103e1f:	85 ff                	test   %edi,%edi
  103e21:	74 3d                	je     103e60 <strncmp+0x50>
  103e23:	0f b6 01             	movzbl (%ecx),%eax
  103e26:	84 c0                	test   %al,%al
  103e28:	75 18                	jne    103e42 <strncmp+0x32>
  103e2a:	eb 3c                	jmp    103e68 <strncmp+0x58>
  103e2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103e30:	83 ef 01             	sub    $0x1,%edi
  103e33:	74 2b                	je     103e60 <strncmp+0x50>
    n--, p++, q++;
  103e35:	83 c1 01             	add    $0x1,%ecx
  103e38:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
  103e3b:	0f b6 01             	movzbl (%ecx),%eax
  103e3e:	84 c0                	test   %al,%al
  103e40:	74 26                	je     103e68 <strncmp+0x58>
  103e42:	0f b6 33             	movzbl (%ebx),%esi
  103e45:	89 f2                	mov    %esi,%edx
  103e47:	38 d0                	cmp    %dl,%al
  103e49:	74 e5                	je     103e30 <strncmp+0x20>
    n--, p++, q++;
  if(n == 0)
    return 0;
  return (uchar)*p - (uchar)*q;
  103e4b:	81 e6 ff 00 00 00    	and    $0xff,%esi
  103e51:	0f b6 c0             	movzbl %al,%eax
  103e54:	29 f0                	sub    %esi,%eax
}
  103e56:	5b                   	pop    %ebx
  103e57:	5e                   	pop    %esi
  103e58:	5f                   	pop    %edi
  103e59:	5d                   	pop    %ebp
  103e5a:	c3                   	ret    
  103e5b:	90                   	nop
  103e5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
  103e60:	31 c0                	xor    %eax,%eax
    n--, p++, q++;
  if(n == 0)
    return 0;
  return (uchar)*p - (uchar)*q;
}
  103e62:	5b                   	pop    %ebx
  103e63:	5e                   	pop    %esi
  103e64:	5f                   	pop    %edi
  103e65:	5d                   	pop    %ebp
  103e66:	c3                   	ret    
  103e67:	90                   	nop
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
  103e68:	0f b6 33             	movzbl (%ebx),%esi
  103e6b:	eb de                	jmp    103e4b <strncmp+0x3b>
  103e6d:	8d 76 00             	lea    0x0(%esi),%esi

00103e70 <strncpy>:
  return (uchar)*p - (uchar)*q;
}

char*
strncpy(char *s, const char *t, int n)
{
  103e70:	55                   	push   %ebp
  103e71:	89 e5                	mov    %esp,%ebp
  103e73:	8b 45 08             	mov    0x8(%ebp),%eax
  103e76:	56                   	push   %esi
  103e77:	8b 4d 10             	mov    0x10(%ebp),%ecx
  103e7a:	53                   	push   %ebx
  103e7b:	8b 75 0c             	mov    0xc(%ebp),%esi
  103e7e:	89 c3                	mov    %eax,%ebx
  103e80:	eb 09                	jmp    103e8b <strncpy+0x1b>
  103e82:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
  103e88:	83 c6 01             	add    $0x1,%esi
  103e8b:	83 e9 01             	sub    $0x1,%ecx
    return 0;
  return (uchar)*p - (uchar)*q;
}

char*
strncpy(char *s, const char *t, int n)
  103e8e:	8d 51 01             	lea    0x1(%ecx),%edx
{
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
  103e91:	85 d2                	test   %edx,%edx
  103e93:	7e 0c                	jle    103ea1 <strncpy+0x31>
  103e95:	0f b6 16             	movzbl (%esi),%edx
  103e98:	88 13                	mov    %dl,(%ebx)
  103e9a:	83 c3 01             	add    $0x1,%ebx
  103e9d:	84 d2                	test   %dl,%dl
  103e9f:	75 e7                	jne    103e88 <strncpy+0x18>
    return 0;
  return (uchar)*p - (uchar)*q;
}

char*
strncpy(char *s, const char *t, int n)
  103ea1:	31 d2                	xor    %edx,%edx
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
  103ea3:	85 c9                	test   %ecx,%ecx
  103ea5:	7e 0c                	jle    103eb3 <strncpy+0x43>
  103ea7:	90                   	nop
    *s++ = 0;
  103ea8:	c6 04 13 00          	movb   $0x0,(%ebx,%edx,1)
  103eac:	83 c2 01             	add    $0x1,%edx
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
  103eaf:	39 ca                	cmp    %ecx,%edx
  103eb1:	75 f5                	jne    103ea8 <strncpy+0x38>
    *s++ = 0;
  return os;
}
  103eb3:	5b                   	pop    %ebx
  103eb4:	5e                   	pop    %esi
  103eb5:	5d                   	pop    %ebp
  103eb6:	c3                   	ret    
  103eb7:	89 f6                	mov    %esi,%esi
  103eb9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103ec0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
  103ec0:	55                   	push   %ebp
  103ec1:	89 e5                	mov    %esp,%ebp
  103ec3:	8b 55 10             	mov    0x10(%ebp),%edx
  103ec6:	56                   	push   %esi
  103ec7:	8b 45 08             	mov    0x8(%ebp),%eax
  103eca:	53                   	push   %ebx
  103ecb:	8b 75 0c             	mov    0xc(%ebp),%esi
  char *os;
  
  os = s;
  if(n <= 0)
  103ece:	85 d2                	test   %edx,%edx
  103ed0:	7e 1f                	jle    103ef1 <safestrcpy+0x31>
  103ed2:	89 c1                	mov    %eax,%ecx
  103ed4:	eb 05                	jmp    103edb <safestrcpy+0x1b>
  103ed6:	66 90                	xchg   %ax,%ax
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
  103ed8:	83 c6 01             	add    $0x1,%esi
  103edb:	83 ea 01             	sub    $0x1,%edx
  103ede:	85 d2                	test   %edx,%edx
  103ee0:	7e 0c                	jle    103eee <safestrcpy+0x2e>
  103ee2:	0f b6 1e             	movzbl (%esi),%ebx
  103ee5:	88 19                	mov    %bl,(%ecx)
  103ee7:	83 c1 01             	add    $0x1,%ecx
  103eea:	84 db                	test   %bl,%bl
  103eec:	75 ea                	jne    103ed8 <safestrcpy+0x18>
    ;
  *s = 0;
  103eee:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
  103ef1:	5b                   	pop    %ebx
  103ef2:	5e                   	pop    %esi
  103ef3:	5d                   	pop    %ebp
  103ef4:	c3                   	ret    
  103ef5:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103ef9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103f00 <strlen>:

int
strlen(const char *s)
{
  103f00:	55                   	push   %ebp
  int n;

  for(n = 0; s[n]; n++)
  103f01:	31 c0                	xor    %eax,%eax
  return os;
}

int
strlen(const char *s)
{
  103f03:	89 e5                	mov    %esp,%ebp
  103f05:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
  103f08:	80 3a 00             	cmpb   $0x0,(%edx)
  103f0b:	74 0c                	je     103f19 <strlen+0x19>
  103f0d:	8d 76 00             	lea    0x0(%esi),%esi
  103f10:	83 c0 01             	add    $0x1,%eax
  103f13:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  103f17:	75 f7                	jne    103f10 <strlen+0x10>
    ;
  return n;
}
  103f19:	5d                   	pop    %ebp
  103f1a:	c3                   	ret    
  103f1b:	90                   	nop

00103f1c <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
  103f1c:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
  103f20:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
  103f24:	55                   	push   %ebp
  pushl %ebx
  103f25:	53                   	push   %ebx
  pushl %esi
  103f26:	56                   	push   %esi
  pushl %edi
  103f27:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
  103f28:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
  103f2a:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
  103f2c:	5f                   	pop    %edi
  popl %esi
  103f2d:	5e                   	pop    %esi
  popl %ebx
  103f2e:	5b                   	pop    %ebx
  popl %ebp
  103f2f:	5d                   	pop    %ebp
  ret
  103f30:	c3                   	ret    
  103f31:	90                   	nop
  103f32:	90                   	nop
  103f33:	90                   	nop
  103f34:	90                   	nop
  103f35:	90                   	nop
  103f36:	90                   	nop
  103f37:	90                   	nop
  103f38:	90                   	nop
  103f39:	90                   	nop
  103f3a:	90                   	nop
  103f3b:	90                   	nop
  103f3c:	90                   	nop
  103f3d:	90                   	nop
  103f3e:	90                   	nop
  103f3f:	90                   	nop

00103f40 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  103f40:	55                   	push   %ebp
  103f41:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
  103f43:	8b 55 08             	mov    0x8(%ebp),%edx
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  103f46:	8b 45 0c             	mov    0xc(%ebp),%eax
  if(addr >= p->sz || addr+4 > p->sz)
  103f49:	8b 12                	mov    (%edx),%edx
  103f4b:	39 c2                	cmp    %eax,%edx
  103f4d:	77 09                	ja     103f58 <fetchint+0x18>
    return -1;
  *ip = *(int*)(addr);
  return 0;
  103f4f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  103f54:	5d                   	pop    %ebp
  103f55:	c3                   	ret    
  103f56:	66 90                	xchg   %ax,%ax

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103f58:	8d 48 04             	lea    0x4(%eax),%ecx
  103f5b:	39 ca                	cmp    %ecx,%edx
  103f5d:	72 f0                	jb     103f4f <fetchint+0xf>
    return -1;
  *ip = *(int*)(addr);
  103f5f:	8b 10                	mov    (%eax),%edx
  103f61:	8b 45 10             	mov    0x10(%ebp),%eax
  103f64:	89 10                	mov    %edx,(%eax)
  103f66:	31 c0                	xor    %eax,%eax
  return 0;
}
  103f68:	5d                   	pop    %ebp
  103f69:	c3                   	ret    
  103f6a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00103f70 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
  103f70:	55                   	push   %ebp
  103f71:	89 e5                	mov    %esp,%ebp
  103f73:	8b 45 08             	mov    0x8(%ebp),%eax
  103f76:	8b 55 0c             	mov    0xc(%ebp),%edx
  103f79:	53                   	push   %ebx
  char *s, *ep;

  if(addr >= p->sz)
  103f7a:	39 10                	cmp    %edx,(%eax)
  103f7c:	77 0a                	ja     103f88 <fetchstr+0x18>
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
  103f7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    if(*s == 0)
      return s - *pp;
  return -1;
}
  103f83:	5b                   	pop    %ebx
  103f84:	5d                   	pop    %ebp
  103f85:	c3                   	ret    
  103f86:	66 90                	xchg   %ax,%ax
{
  char *s, *ep;

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  103f88:	8b 4d 10             	mov    0x10(%ebp),%ecx
  103f8b:	89 11                	mov    %edx,(%ecx)
  ep = (char*)p->sz;
  103f8d:	8b 18                	mov    (%eax),%ebx
  for(s = *pp; s < ep; s++)
  103f8f:	39 da                	cmp    %ebx,%edx
  103f91:	73 eb                	jae    103f7e <fetchstr+0xe>
    if(*s == 0)
  103f93:	31 c0                	xor    %eax,%eax
  103f95:	89 d1                	mov    %edx,%ecx
  103f97:	80 3a 00             	cmpb   $0x0,(%edx)
  103f9a:	74 e7                	je     103f83 <fetchstr+0x13>
  103f9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
  103fa0:	83 c1 01             	add    $0x1,%ecx
  103fa3:	39 cb                	cmp    %ecx,%ebx
  103fa5:	76 d7                	jbe    103f7e <fetchstr+0xe>
    if(*s == 0)
  103fa7:	80 39 00             	cmpb   $0x0,(%ecx)
  103faa:	75 f4                	jne    103fa0 <fetchstr+0x30>
  103fac:	89 c8                	mov    %ecx,%eax
  103fae:	29 d0                	sub    %edx,%eax
  103fb0:	eb d1                	jmp    103f83 <fetchstr+0x13>
  103fb2:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  103fb9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00103fc0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103fc0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
}

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  103fc6:	55                   	push   %ebp
  103fc7:	89 e5                	mov    %esp,%ebp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103fc9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103fcc:	8b 50 18             	mov    0x18(%eax),%edx

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103fcf:	8b 00                	mov    (%eax),%eax

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  103fd1:	8b 52 44             	mov    0x44(%edx),%edx
  103fd4:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103fd8:	39 c2                	cmp    %eax,%edx
  103fda:	72 0c                	jb     103fe8 <argint+0x28>
    return -1;
  *ip = *(int*)(addr);
  103fdc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
}
  103fe1:	5d                   	pop    %ebp
  103fe2:	c3                   	ret    
  103fe3:	90                   	nop
  103fe4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  103fe8:	8d 4a 04             	lea    0x4(%edx),%ecx
  103feb:	39 c8                	cmp    %ecx,%eax
  103fed:	72 ed                	jb     103fdc <argint+0x1c>
    return -1;
  *ip = *(int*)(addr);
  103fef:	8b 45 0c             	mov    0xc(%ebp),%eax
  103ff2:	8b 12                	mov    (%edx),%edx
  103ff4:	89 10                	mov    %edx,(%eax)
  103ff6:	31 c0                	xor    %eax,%eax
// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
}
  103ff8:	5d                   	pop    %ebp
  103ff9:	c3                   	ret    
  103ffa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00104000 <argptr>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  104000:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
  104006:	55                   	push   %ebp
  104007:	89 e5                	mov    %esp,%ebp

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  104009:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10400c:	8b 50 18             	mov    0x18(%eax),%edx

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  10400f:	8b 00                	mov    (%eax),%eax

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  104011:	8b 52 44             	mov    0x44(%edx),%edx
  104014:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  104018:	39 c2                	cmp    %eax,%edx
  10401a:	73 07                	jae    104023 <argptr+0x23>
  10401c:	8d 4a 04             	lea    0x4(%edx),%ecx
  10401f:	39 c8                	cmp    %ecx,%eax
  104021:	73 0d                	jae    104030 <argptr+0x30>
  if(argint(n, &i) < 0)
    return -1;
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
    return -1;
  *pp = (char*)i;
  return 0;
  104023:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104028:	5d                   	pop    %ebp
  104029:	c3                   	ret    
  10402a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
    return -1;
  *ip = *(int*)(addr);
  104030:	8b 12                	mov    (%edx),%edx
{
  int i;
  
  if(argint(n, &i) < 0)
    return -1;
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
  104032:	39 c2                	cmp    %eax,%edx
  104034:	73 ed                	jae    104023 <argptr+0x23>
  104036:	8b 4d 10             	mov    0x10(%ebp),%ecx
  104039:	01 d1                	add    %edx,%ecx
  10403b:	39 c1                	cmp    %eax,%ecx
  10403d:	77 e4                	ja     104023 <argptr+0x23>
    return -1;
  *pp = (char*)i;
  10403f:	8b 45 0c             	mov    0xc(%ebp),%eax
  104042:	89 10                	mov    %edx,(%eax)
  104044:	31 c0                	xor    %eax,%eax
  return 0;
}
  104046:	5d                   	pop    %ebp
  104047:	c3                   	ret    
  104048:	90                   	nop
  104049:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00104050 <argstr>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  104050:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
  104057:	55                   	push   %ebp
  104058:	89 e5                	mov    %esp,%ebp
  10405a:	53                   	push   %ebx

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
  10405b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10405e:	8b 42 18             	mov    0x18(%edx),%eax
  104061:	8b 40 44             	mov    0x44(%eax),%eax
  104064:	8d 44 88 04          	lea    0x4(%eax,%ecx,4),%eax

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
  104068:	8b 0a                	mov    (%edx),%ecx
  10406a:	39 c8                	cmp    %ecx,%eax
  10406c:	73 07                	jae    104075 <argstr+0x25>
  10406e:	8d 58 04             	lea    0x4(%eax),%ebx
  104071:	39 d9                	cmp    %ebx,%ecx
  104073:	73 0b                	jae    104080 <argstr+0x30>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
  104075:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
{
  int addr;
  if(argint(n, &addr) < 0)
    return -1;
  return fetchstr(proc, addr, pp);
}
  10407a:	5b                   	pop    %ebx
  10407b:	5d                   	pop    %ebp
  10407c:	c3                   	ret    
  10407d:	8d 76 00             	lea    0x0(%esi),%esi
int
fetchint(struct proc *p, uint addr, int *ip)
{
  if(addr >= p->sz || addr+4 > p->sz)
    return -1;
  *ip = *(int*)(addr);
  104080:	8b 18                	mov    (%eax),%ebx
int
fetchstr(struct proc *p, uint addr, char **pp)
{
  char *s, *ep;

  if(addr >= p->sz)
  104082:	39 cb                	cmp    %ecx,%ebx
  104084:	73 ef                	jae    104075 <argstr+0x25>
    return -1;
  *pp = (char*)addr;
  104086:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  104089:	89 d8                	mov    %ebx,%eax
  10408b:	89 19                	mov    %ebx,(%ecx)
  ep = (char*)p->sz;
  10408d:	8b 12                	mov    (%edx),%edx
  for(s = *pp; s < ep; s++)
  10408f:	39 d3                	cmp    %edx,%ebx
  104091:	73 e2                	jae    104075 <argstr+0x25>
    if(*s == 0)
  104093:	80 3b 00             	cmpb   $0x0,(%ebx)
  104096:	75 12                	jne    1040aa <argstr+0x5a>
  104098:	eb 1e                	jmp    1040b8 <argstr+0x68>
  10409a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1040a0:	80 38 00             	cmpb   $0x0,(%eax)
  1040a3:	90                   	nop
  1040a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1040a8:	74 0e                	je     1040b8 <argstr+0x68>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
  1040aa:	83 c0 01             	add    $0x1,%eax
  1040ad:	39 c2                	cmp    %eax,%edx
  1040af:	90                   	nop
  1040b0:	77 ee                	ja     1040a0 <argstr+0x50>
  1040b2:	eb c1                	jmp    104075 <argstr+0x25>
  1040b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if(*s == 0)
      return s - *pp;
  1040b8:	29 d8                	sub    %ebx,%eax
{
  int addr;
  if(argint(n, &addr) < 0)
    return -1;
  return fetchstr(proc, addr, pp);
}
  1040ba:	5b                   	pop    %ebx
  1040bb:	5d                   	pop    %ebp
  1040bc:	c3                   	ret    
  1040bd:	8d 76 00             	lea    0x0(%esi),%esi

001040c0 <syscall>:
[SYS_clone]   sys_clone,
};

void
syscall(void)
{
  1040c0:	55                   	push   %ebp
  1040c1:	89 e5                	mov    %esp,%ebp
  1040c3:	53                   	push   %ebx
  1040c4:	83 ec 14             	sub    $0x14,%esp
  int num;

  num = proc->tf->eax;
  1040c7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1040ce:	8b 5a 18             	mov    0x18(%edx),%ebx
  1040d1:	8b 43 1c             	mov    0x1c(%ebx),%eax
  if(num >= 0 && num < NELEM(syscalls) && syscalls[num])
  1040d4:	83 f8 16             	cmp    $0x16,%eax
  1040d7:	77 17                	ja     1040f0 <syscall+0x30>
  1040d9:	8b 0c 85 00 6c 10 00 	mov    0x106c00(,%eax,4),%ecx
  1040e0:	85 c9                	test   %ecx,%ecx
  1040e2:	74 0c                	je     1040f0 <syscall+0x30>
    proc->tf->eax = syscalls[num]();
  1040e4:	ff d1                	call   *%ecx
  1040e6:	89 43 1c             	mov    %eax,0x1c(%ebx)
  else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
  }
}
  1040e9:	83 c4 14             	add    $0x14,%esp
  1040ec:	5b                   	pop    %ebx
  1040ed:	5d                   	pop    %ebp
  1040ee:	c3                   	ret    
  1040ef:	90                   	nop

  num = proc->tf->eax;
  if(num >= 0 && num < NELEM(syscalls) && syscalls[num])
    proc->tf->eax = syscalls[num]();
  else {
    cprintf("%d %s: unknown sys call %d\n",
  1040f0:	8b 4a 10             	mov    0x10(%edx),%ecx
  1040f3:	83 c2 6c             	add    $0x6c,%edx
  1040f6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1040fa:	89 54 24 08          	mov    %edx,0x8(%esp)
  1040fe:	c7 04 24 ca 6b 10 00 	movl   $0x106bca,(%esp)
  104105:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  104109:	e8 22 c4 ff ff       	call   100530 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
  10410e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104114:	8b 40 18             	mov    0x18(%eax),%eax
  104117:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
  10411e:	83 c4 14             	add    $0x14,%esp
  104121:	5b                   	pop    %ebx
  104122:	5d                   	pop    %ebp
  104123:	c3                   	ret    
  104124:	90                   	nop
  104125:	90                   	nop
  104126:	90                   	nop
  104127:	90                   	nop
  104128:	90                   	nop
  104129:	90                   	nop
  10412a:	90                   	nop
  10412b:	90                   	nop
  10412c:	90                   	nop
  10412d:	90                   	nop
  10412e:	90                   	nop
  10412f:	90                   	nop

00104130 <sys_pipe>:
  return exec(path, argv);
}

int
sys_pipe(void)
{
  104130:	55                   	push   %ebp
  104131:	89 e5                	mov    %esp,%ebp
  104133:	83 ec 28             	sub    $0x28,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
  104136:	8d 45 f4             	lea    -0xc(%ebp),%eax
  return exec(path, argv);
}

int
sys_pipe(void)
{
  104139:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  10413c:	89 75 fc             	mov    %esi,-0x4(%ebp)
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
  10413f:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
  104146:	00 
  104147:	89 44 24 04          	mov    %eax,0x4(%esp)
  10414b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104152:	e8 a9 fe ff ff       	call   104000 <argptr>
  104157:	85 c0                	test   %eax,%eax
  104159:	79 15                	jns    104170 <sys_pipe+0x40>
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    if(fd0 >= 0)
      proc->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  10415b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  fd[0] = fd0;
  fd[1] = fd1;
  return 0;
}
  104160:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  104163:	8b 75 fc             	mov    -0x4(%ebp),%esi
  104166:	89 ec                	mov    %ebp,%esp
  104168:	5d                   	pop    %ebp
  104169:	c3                   	ret    
  10416a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
    return -1;
  if(pipealloc(&rf, &wf) < 0)
  104170:	8d 45 ec             	lea    -0x14(%ebp),%eax
  104173:	89 44 24 04          	mov    %eax,0x4(%esp)
  104177:	8d 45 f0             	lea    -0x10(%ebp),%eax
  10417a:	89 04 24             	mov    %eax,(%esp)
  10417d:	e8 6e ed ff ff       	call   102ef0 <pipealloc>
  104182:	85 c0                	test   %eax,%eax
  104184:	78 d5                	js     10415b <sys_pipe+0x2b>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
  104186:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  104189:	31 c0                	xor    %eax,%eax
  10418b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  104192:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
  104198:	8b 5c 82 28          	mov    0x28(%edx,%eax,4),%ebx
  10419c:	85 db                	test   %ebx,%ebx
  10419e:	74 28                	je     1041c8 <sys_pipe+0x98>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
  1041a0:	83 c0 01             	add    $0x1,%eax
  1041a3:	83 f8 10             	cmp    $0x10,%eax
  1041a6:	75 f0                	jne    104198 <sys_pipe+0x68>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    if(fd0 >= 0)
      proc->ofile[fd0] = 0;
    fileclose(rf);
  1041a8:	89 0c 24             	mov    %ecx,(%esp)
  1041ab:	e8 c0 cd ff ff       	call   100f70 <fileclose>
    fileclose(wf);
  1041b0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1041b3:	89 04 24             	mov    %eax,(%esp)
  1041b6:	e8 b5 cd ff ff       	call   100f70 <fileclose>
  1041bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    return -1;
  1041c0:	eb 9e                	jmp    104160 <sys_pipe+0x30>
  1041c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
  1041c8:	8d 58 08             	lea    0x8(%eax),%ebx
  1041cb:	89 4c 9a 08          	mov    %ecx,0x8(%edx,%ebx,4)
  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
    return -1;
  if(pipealloc(&rf, &wf) < 0)
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
  1041cf:	8b 75 ec             	mov    -0x14(%ebp),%esi
  1041d2:	31 d2                	xor    %edx,%edx
  1041d4:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
  1041db:	90                   	nop
  1041dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
  1041e0:	83 7c 91 28 00       	cmpl   $0x0,0x28(%ecx,%edx,4)
  1041e5:	74 19                	je     104200 <sys_pipe+0xd0>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
  1041e7:	83 c2 01             	add    $0x1,%edx
  1041ea:	83 fa 10             	cmp    $0x10,%edx
  1041ed:	75 f1                	jne    1041e0 <sys_pipe+0xb0>
  if(pipealloc(&rf, &wf) < 0)
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    if(fd0 >= 0)
      proc->ofile[fd0] = 0;
  1041ef:	c7 44 99 08 00 00 00 	movl   $0x0,0x8(%ecx,%ebx,4)
  1041f6:	00 
  1041f7:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  1041fa:	eb ac                	jmp    1041a8 <sys_pipe+0x78>
  1041fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
  104200:	89 74 91 28          	mov    %esi,0x28(%ecx,%edx,4)
      proc->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
  104204:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  104207:	89 01                	mov    %eax,(%ecx)
  fd[1] = fd1;
  104209:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10420c:	89 50 04             	mov    %edx,0x4(%eax)
  10420f:	31 c0                	xor    %eax,%eax
  return 0;
  104211:	e9 4a ff ff ff       	jmp    104160 <sys_pipe+0x30>
  104216:	8d 76 00             	lea    0x0(%esi),%esi
  104219:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00104220 <sys_exec>:
  return 0;
}

int
sys_exec(void)
{
  104220:	55                   	push   %ebp
  104221:	89 e5                	mov    %esp,%ebp
  104223:	81 ec b8 00 00 00    	sub    $0xb8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
  104229:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  return 0;
}

int
sys_exec(void)
{
  10422c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  10422f:	89 75 f8             	mov    %esi,-0x8(%ebp)
  104232:	89 7d fc             	mov    %edi,-0x4(%ebp)
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
  104235:	89 44 24 04          	mov    %eax,0x4(%esp)
  104239:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104240:	e8 0b fe ff ff       	call   104050 <argstr>
  104245:	85 c0                	test   %eax,%eax
  104247:	79 17                	jns    104260 <sys_exec+0x40>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
    if(i >= NELEM(argv))
  104249:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
}
  10424e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  104251:	8b 75 f8             	mov    -0x8(%ebp),%esi
  104254:	8b 7d fc             	mov    -0x4(%ebp),%edi
  104257:	89 ec                	mov    %ebp,%esp
  104259:	5d                   	pop    %ebp
  10425a:	c3                   	ret    
  10425b:	90                   	nop
  10425c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
  104260:	8d 45 e0             	lea    -0x20(%ebp),%eax
  104263:	89 44 24 04          	mov    %eax,0x4(%esp)
  104267:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10426e:	e8 4d fd ff ff       	call   103fc0 <argint>
  104273:	85 c0                	test   %eax,%eax
  104275:	78 d2                	js     104249 <sys_exec+0x29>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  104277:	8d bd 5c ff ff ff    	lea    -0xa4(%ebp),%edi
  10427d:	31 f6                	xor    %esi,%esi
  10427f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  104286:	00 
  104287:	31 db                	xor    %ebx,%ebx
  104289:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104290:	00 
  104291:	89 3c 24             	mov    %edi,(%esp)
  104294:	e8 87 fa ff ff       	call   103d20 <memset>
  104299:	eb 2c                	jmp    1042c7 <sys_exec+0xa7>
  10429b:	90                   	nop
  10429c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
  1042a0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1042a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1042aa:	8d 14 b7             	lea    (%edi,%esi,4),%edx
  1042ad:	89 54 24 08          	mov    %edx,0x8(%esp)
  1042b1:	89 04 24             	mov    %eax,(%esp)
  1042b4:	e8 b7 fc ff ff       	call   103f70 <fetchstr>
  1042b9:	85 c0                	test   %eax,%eax
  1042bb:	78 8c                	js     104249 <sys_exec+0x29>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
  1042bd:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
  1042c0:	83 fb 20             	cmp    $0x20,%ebx

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
  1042c3:	89 de                	mov    %ebx,%esi
    if(i >= NELEM(argv))
  1042c5:	74 82                	je     104249 <sys_exec+0x29>
      return -1;
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
  1042c7:	8d 45 dc             	lea    -0x24(%ebp),%eax
  1042ca:	89 44 24 08          	mov    %eax,0x8(%esp)
  1042ce:	8d 04 9d 00 00 00 00 	lea    0x0(,%ebx,4),%eax
  1042d5:	03 45 e0             	add    -0x20(%ebp),%eax
  1042d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1042dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1042e2:	89 04 24             	mov    %eax,(%esp)
  1042e5:	e8 56 fc ff ff       	call   103f40 <fetchint>
  1042ea:	85 c0                	test   %eax,%eax
  1042ec:	0f 88 57 ff ff ff    	js     104249 <sys_exec+0x29>
      return -1;
    if(uarg == 0){
  1042f2:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1042f5:	85 c0                	test   %eax,%eax
  1042f7:	75 a7                	jne    1042a0 <sys_exec+0x80>
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
  1042f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    if(i >= NELEM(argv))
      return -1;
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
      return -1;
    if(uarg == 0){
      argv[i] = 0;
  1042fc:	c7 84 9d 5c ff ff ff 	movl   $0x0,-0xa4(%ebp,%ebx,4)
  104303:	00 00 00 00 
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
  104307:	89 7c 24 04          	mov    %edi,0x4(%esp)
  10430b:	89 04 24             	mov    %eax,(%esp)
  10430e:	e8 8d c6 ff ff       	call   1009a0 <exec>
  104313:	e9 36 ff ff ff       	jmp    10424e <sys_exec+0x2e>
  104318:	90                   	nop
  104319:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00104320 <sys_chdir>:
  return 0;
}

int
sys_chdir(void)
{
  104320:	55                   	push   %ebp
  104321:	89 e5                	mov    %esp,%ebp
  104323:	53                   	push   %ebx
  104324:	83 ec 24             	sub    $0x24,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
  104327:	8d 45 f4             	lea    -0xc(%ebp),%eax
  10432a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10432e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104335:	e8 16 fd ff ff       	call   104050 <argstr>
  10433a:	85 c0                	test   %eax,%eax
  10433c:	79 12                	jns    104350 <sys_chdir+0x30>
    return -1;
  }
  iunlock(ip);
  iput(proc->cwd);
  proc->cwd = ip;
  return 0;
  10433e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104343:	83 c4 24             	add    $0x24,%esp
  104346:	5b                   	pop    %ebx
  104347:	5d                   	pop    %ebp
  104348:	c3                   	ret    
  104349:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
sys_chdir(void)
{
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
  104350:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104353:	89 04 24             	mov    %eax,(%esp)
  104356:	e8 f5 da ff ff       	call   101e50 <namei>
  10435b:	85 c0                	test   %eax,%eax
  10435d:	89 c3                	mov    %eax,%ebx
  10435f:	74 dd                	je     10433e <sys_chdir+0x1e>
    return -1;
  ilock(ip);
  104361:	89 04 24             	mov    %eax,(%esp)
  104364:	e8 47 d8 ff ff       	call   101bb0 <ilock>
  if(ip->type != T_DIR){
  104369:	66 83 7b 10 01       	cmpw   $0x1,0x10(%ebx)
  10436e:	75 26                	jne    104396 <sys_chdir+0x76>
    iunlockput(ip);
    return -1;
  }
  iunlock(ip);
  104370:	89 1c 24             	mov    %ebx,(%esp)
  104373:	e8 f8 d3 ff ff       	call   101770 <iunlock>
  iput(proc->cwd);
  104378:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  10437e:	8b 40 68             	mov    0x68(%eax),%eax
  104381:	89 04 24             	mov    %eax,(%esp)
  104384:	e8 f7 d4 ff ff       	call   101880 <iput>
  proc->cwd = ip;
  104389:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  10438f:	89 58 68             	mov    %ebx,0x68(%eax)
  104392:	31 c0                	xor    %eax,%eax
  return 0;
  104394:	eb ad                	jmp    104343 <sys_chdir+0x23>

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
    return -1;
  ilock(ip);
  if(ip->type != T_DIR){
    iunlockput(ip);
  104396:	89 1c 24             	mov    %ebx,(%esp)
  104399:	e8 22 d7 ff ff       	call   101ac0 <iunlockput>
  10439e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    return -1;
  1043a3:	eb 9e                	jmp    104343 <sys_chdir+0x23>
  1043a5:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1043a9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001043b0 <create>:
  return 0;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
  1043b0:	55                   	push   %ebp
  1043b1:	89 e5                	mov    %esp,%ebp
  1043b3:	83 ec 58             	sub    $0x58,%esp
  1043b6:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
  1043b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1043bc:	89 75 f8             	mov    %esi,-0x8(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
  1043bf:	8d 75 d6             	lea    -0x2a(%ebp),%esi
  return 0;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
  1043c2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
  1043c5:	31 db                	xor    %ebx,%ebx
  return 0;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
  1043c7:	89 7d fc             	mov    %edi,-0x4(%ebp)
  1043ca:	89 d7                	mov    %edx,%edi
  1043cc:	89 4d c0             	mov    %ecx,-0x40(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
  1043cf:	89 74 24 04          	mov    %esi,0x4(%esp)
  1043d3:	89 04 24             	mov    %eax,(%esp)
  1043d6:	e8 55 da ff ff       	call   101e30 <nameiparent>
  1043db:	85 c0                	test   %eax,%eax
  1043dd:	74 47                	je     104426 <create+0x76>
    return 0;
  ilock(dp);
  1043df:	89 04 24             	mov    %eax,(%esp)
  1043e2:	89 45 bc             	mov    %eax,-0x44(%ebp)
  1043e5:	e8 c6 d7 ff ff       	call   101bb0 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
  1043ea:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1043ed:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  1043f0:	89 44 24 08          	mov    %eax,0x8(%esp)
  1043f4:	89 74 24 04          	mov    %esi,0x4(%esp)
  1043f8:	89 14 24             	mov    %edx,(%esp)
  1043fb:	e8 70 d2 ff ff       	call   101670 <dirlookup>
  104400:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104403:	85 c0                	test   %eax,%eax
  104405:	89 c3                	mov    %eax,%ebx
  104407:	74 3f                	je     104448 <create+0x98>
    iunlockput(dp);
  104409:	89 14 24             	mov    %edx,(%esp)
  10440c:	e8 af d6 ff ff       	call   101ac0 <iunlockput>
    ilock(ip);
  104411:	89 1c 24             	mov    %ebx,(%esp)
  104414:	e8 97 d7 ff ff       	call   101bb0 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
  104419:	66 83 ff 02          	cmp    $0x2,%di
  10441d:	75 19                	jne    104438 <create+0x88>
  10441f:	66 83 7b 10 02       	cmpw   $0x2,0x10(%ebx)
  104424:	75 12                	jne    104438 <create+0x88>
  if(dirlink(dp, name, ip->inum) < 0)
    panic("create: dirlink");

  iunlockput(dp);
  return ip;
}
  104426:	89 d8                	mov    %ebx,%eax
  104428:	8b 75 f8             	mov    -0x8(%ebp),%esi
  10442b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10442e:	8b 7d fc             	mov    -0x4(%ebp),%edi
  104431:	89 ec                	mov    %ebp,%esp
  104433:	5d                   	pop    %ebp
  104434:	c3                   	ret    
  104435:	8d 76 00             	lea    0x0(%esi),%esi
  if((ip = dirlookup(dp, name, &off)) != 0){
    iunlockput(dp);
    ilock(ip);
    if(type == T_FILE && ip->type == T_FILE)
      return ip;
    iunlockput(ip);
  104438:	89 1c 24             	mov    %ebx,(%esp)
  10443b:	31 db                	xor    %ebx,%ebx
  10443d:	e8 7e d6 ff ff       	call   101ac0 <iunlockput>
    return 0;
  104442:	eb e2                	jmp    104426 <create+0x76>
  104444:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  }

  if((ip = ialloc(dp->dev, type)) == 0)
  104448:	0f bf c7             	movswl %di,%eax
  10444b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10444f:	8b 02                	mov    (%edx),%eax
  104451:	89 55 bc             	mov    %edx,-0x44(%ebp)
  104454:	89 04 24             	mov    %eax,(%esp)
  104457:	e8 84 d6 ff ff       	call   101ae0 <ialloc>
  10445c:	8b 55 bc             	mov    -0x44(%ebp),%edx
  10445f:	85 c0                	test   %eax,%eax
  104461:	89 c3                	mov    %eax,%ebx
  104463:	0f 84 b7 00 00 00    	je     104520 <create+0x170>
    panic("create: ialloc");

  ilock(ip);
  104469:	89 55 bc             	mov    %edx,-0x44(%ebp)
  10446c:	89 04 24             	mov    %eax,(%esp)
  10446f:	e8 3c d7 ff ff       	call   101bb0 <ilock>
  ip->major = major;
  104474:	0f b7 45 c4          	movzwl -0x3c(%ebp),%eax
  104478:	66 89 43 12          	mov    %ax,0x12(%ebx)
  ip->minor = minor;
  10447c:	0f b7 4d c0          	movzwl -0x40(%ebp),%ecx
  ip->nlink = 1;
  104480:	66 c7 43 16 01 00    	movw   $0x1,0x16(%ebx)
  if((ip = ialloc(dp->dev, type)) == 0)
    panic("create: ialloc");

  ilock(ip);
  ip->major = major;
  ip->minor = minor;
  104486:	66 89 4b 14          	mov    %cx,0x14(%ebx)
  ip->nlink = 1;
  iupdate(ip);
  10448a:	89 1c 24             	mov    %ebx,(%esp)
  10448d:	e8 de cf ff ff       	call   101470 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
  104492:	66 83 ff 01          	cmp    $0x1,%di
  104496:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104499:	74 2d                	je     1044c8 <create+0x118>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
      panic("create dots");
  }

  if(dirlink(dp, name, ip->inum) < 0)
  10449b:	8b 43 04             	mov    0x4(%ebx),%eax
  10449e:	89 14 24             	mov    %edx,(%esp)
  1044a1:	89 55 bc             	mov    %edx,-0x44(%ebp)
  1044a4:	89 74 24 04          	mov    %esi,0x4(%esp)
  1044a8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1044ac:	e8 1f d5 ff ff       	call   1019d0 <dirlink>
  1044b1:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1044b4:	85 c0                	test   %eax,%eax
  1044b6:	78 74                	js     10452c <create+0x17c>
    panic("create: dirlink");

  iunlockput(dp);
  1044b8:	89 14 24             	mov    %edx,(%esp)
  1044bb:	e8 00 d6 ff ff       	call   101ac0 <iunlockput>
  return ip;
  1044c0:	e9 61 ff ff ff       	jmp    104426 <create+0x76>
  1044c5:	8d 76 00             	lea    0x0(%esi),%esi
  ip->minor = minor;
  ip->nlink = 1;
  iupdate(ip);

  if(type == T_DIR){  // Create . and .. entries.
    dp->nlink++;  // for ".."
  1044c8:	66 83 42 16 01       	addw   $0x1,0x16(%edx)
    iupdate(dp);
  1044cd:	89 14 24             	mov    %edx,(%esp)
  1044d0:	89 55 bc             	mov    %edx,-0x44(%ebp)
  1044d3:	e8 98 cf ff ff       	call   101470 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
  1044d8:	8b 43 04             	mov    0x4(%ebx),%eax
  1044db:	c7 44 24 04 6c 6c 10 	movl   $0x106c6c,0x4(%esp)
  1044e2:	00 
  1044e3:	89 1c 24             	mov    %ebx,(%esp)
  1044e6:	89 44 24 08          	mov    %eax,0x8(%esp)
  1044ea:	e8 e1 d4 ff ff       	call   1019d0 <dirlink>
  1044ef:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1044f2:	85 c0                	test   %eax,%eax
  1044f4:	78 1e                	js     104514 <create+0x164>
  1044f6:	8b 42 04             	mov    0x4(%edx),%eax
  1044f9:	c7 44 24 04 6b 6c 10 	movl   $0x106c6b,0x4(%esp)
  104500:	00 
  104501:	89 1c 24             	mov    %ebx,(%esp)
  104504:	89 44 24 08          	mov    %eax,0x8(%esp)
  104508:	e8 c3 d4 ff ff       	call   1019d0 <dirlink>
  10450d:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104510:	85 c0                	test   %eax,%eax
  104512:	79 87                	jns    10449b <create+0xeb>
      panic("create dots");
  104514:	c7 04 24 6e 6c 10 00 	movl   $0x106c6e,(%esp)
  10451b:	e8 00 c4 ff ff       	call   100920 <panic>
    iunlockput(ip);
    return 0;
  }

  if((ip = ialloc(dp->dev, type)) == 0)
    panic("create: ialloc");
  104520:	c7 04 24 5c 6c 10 00 	movl   $0x106c5c,(%esp)
  104527:	e8 f4 c3 ff ff       	call   100920 <panic>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
      panic("create dots");
  }

  if(dirlink(dp, name, ip->inum) < 0)
    panic("create: dirlink");
  10452c:	c7 04 24 7a 6c 10 00 	movl   $0x106c7a,(%esp)
  104533:	e8 e8 c3 ff ff       	call   100920 <panic>
  104538:	90                   	nop
  104539:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00104540 <sys_mknod>:
  return 0;
}

int
sys_mknod(void)
{
  104540:	55                   	push   %ebp
  104541:	89 e5                	mov    %esp,%ebp
  104543:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  if((len=argstr(0, &path)) < 0 ||
  104546:	8d 45 f4             	lea    -0xc(%ebp),%eax
  104549:	89 44 24 04          	mov    %eax,0x4(%esp)
  10454d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104554:	e8 f7 fa ff ff       	call   104050 <argstr>
  104559:	85 c0                	test   %eax,%eax
  10455b:	79 0b                	jns    104568 <sys_mknod+0x28>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0)
    return -1;
  iunlockput(ip);
  return 0;
  10455d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104562:	c9                   	leave  
  104563:	c3                   	ret    
  104564:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  char *path;
  int len;
  int major, minor;
  
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
  104568:	8d 45 f0             	lea    -0x10(%ebp),%eax
  10456b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10456f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104576:	e8 45 fa ff ff       	call   103fc0 <argint>
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  if((len=argstr(0, &path)) < 0 ||
  10457b:	85 c0                	test   %eax,%eax
  10457d:	78 de                	js     10455d <sys_mknod+0x1d>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
  10457f:	8d 45 ec             	lea    -0x14(%ebp),%eax
  104582:	89 44 24 04          	mov    %eax,0x4(%esp)
  104586:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  10458d:	e8 2e fa ff ff       	call   103fc0 <argint>
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  if((len=argstr(0, &path)) < 0 ||
  104592:	85 c0                	test   %eax,%eax
  104594:	78 c7                	js     10455d <sys_mknod+0x1d>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0)
  104596:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
  10459a:	ba 03 00 00 00       	mov    $0x3,%edx
  10459f:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
  1045a3:	89 04 24             	mov    %eax,(%esp)
  1045a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1045a9:	e8 02 fe ff ff       	call   1043b0 <create>
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  if((len=argstr(0, &path)) < 0 ||
  1045ae:	85 c0                	test   %eax,%eax
  1045b0:	74 ab                	je     10455d <sys_mknod+0x1d>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0)
    return -1;
  iunlockput(ip);
  1045b2:	89 04 24             	mov    %eax,(%esp)
  1045b5:	e8 06 d5 ff ff       	call   101ac0 <iunlockput>
  1045ba:	31 c0                	xor    %eax,%eax
  return 0;
}
  1045bc:	c9                   	leave  
  1045bd:	c3                   	ret    
  1045be:	66 90                	xchg   %ax,%ax

001045c0 <sys_mkdir>:
  return fd;
}

int
sys_mkdir(void)
{
  1045c0:	55                   	push   %ebp
  1045c1:	89 e5                	mov    %esp,%ebp
  1045c3:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0)
  1045c6:	8d 45 f4             	lea    -0xc(%ebp),%eax
  1045c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1045cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1045d4:	e8 77 fa ff ff       	call   104050 <argstr>
  1045d9:	85 c0                	test   %eax,%eax
  1045db:	79 0b                	jns    1045e8 <sys_mkdir+0x28>
    return -1;
  iunlockput(ip);
  return 0;
  1045dd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  1045e2:	c9                   	leave  
  1045e3:	c3                   	ret    
  1045e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
sys_mkdir(void)
{
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0)
  1045e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1045ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1045f2:	31 c9                	xor    %ecx,%ecx
  1045f4:	ba 01 00 00 00       	mov    $0x1,%edx
  1045f9:	e8 b2 fd ff ff       	call   1043b0 <create>
  1045fe:	85 c0                	test   %eax,%eax
  104600:	74 db                	je     1045dd <sys_mkdir+0x1d>
    return -1;
  iunlockput(ip);
  104602:	89 04 24             	mov    %eax,(%esp)
  104605:	e8 b6 d4 ff ff       	call   101ac0 <iunlockput>
  10460a:	31 c0                	xor    %eax,%eax
  return 0;
}
  10460c:	c9                   	leave  
  10460d:	c3                   	ret    
  10460e:	66 90                	xchg   %ax,%ax

00104610 <sys_link>:
}

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
  104610:	55                   	push   %ebp
  104611:	89 e5                	mov    %esp,%ebp
  104613:	83 ec 48             	sub    $0x48,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
  104616:	8d 45 e0             	lea    -0x20(%ebp),%eax
}

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
  104619:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  10461c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  10461f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
  104622:	89 44 24 04          	mov    %eax,0x4(%esp)
  104626:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10462d:	e8 1e fa ff ff       	call   104050 <argstr>
  104632:	85 c0                	test   %eax,%eax
  104634:	79 12                	jns    104648 <sys_link+0x38>
bad:
  ilock(ip);
  ip->nlink--;
  iupdate(ip);
  iunlockput(ip);
  return -1;
  104636:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  10463b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10463e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  104641:	8b 7d fc             	mov    -0x4(%ebp),%edi
  104644:	89 ec                	mov    %ebp,%esp
  104646:	5d                   	pop    %ebp
  104647:	c3                   	ret    
sys_link(void)
{
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
  104648:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  10464b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10464f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104656:	e8 f5 f9 ff ff       	call   104050 <argstr>
  10465b:	85 c0                	test   %eax,%eax
  10465d:	78 d7                	js     104636 <sys_link+0x26>
    return -1;
  if((ip = namei(old)) == 0)
  10465f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104662:	89 04 24             	mov    %eax,(%esp)
  104665:	e8 e6 d7 ff ff       	call   101e50 <namei>
  10466a:	85 c0                	test   %eax,%eax
  10466c:	89 c3                	mov    %eax,%ebx
  10466e:	74 c6                	je     104636 <sys_link+0x26>
    return -1;
  ilock(ip);
  104670:	89 04 24             	mov    %eax,(%esp)
  104673:	e8 38 d5 ff ff       	call   101bb0 <ilock>
  if(ip->type == T_DIR){
  104678:	66 83 7b 10 01       	cmpw   $0x1,0x10(%ebx)
  10467d:	0f 84 86 00 00 00    	je     104709 <sys_link+0xf9>
    iunlockput(ip);
    return -1;
  }
  ip->nlink++;
  104683:	66 83 43 16 01       	addw   $0x1,0x16(%ebx)
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
  104688:	8d 7d d2             	lea    -0x2e(%ebp),%edi
  if(ip->type == T_DIR){
    iunlockput(ip);
    return -1;
  }
  ip->nlink++;
  iupdate(ip);
  10468b:	89 1c 24             	mov    %ebx,(%esp)
  10468e:	e8 dd cd ff ff       	call   101470 <iupdate>
  iunlock(ip);
  104693:	89 1c 24             	mov    %ebx,(%esp)
  104696:	e8 d5 d0 ff ff       	call   101770 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
  10469b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10469e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  1046a2:	89 04 24             	mov    %eax,(%esp)
  1046a5:	e8 86 d7 ff ff       	call   101e30 <nameiparent>
  1046aa:	85 c0                	test   %eax,%eax
  1046ac:	89 c6                	mov    %eax,%esi
  1046ae:	74 44                	je     1046f4 <sys_link+0xe4>
    goto bad;
  ilock(dp);
  1046b0:	89 04 24             	mov    %eax,(%esp)
  1046b3:	e8 f8 d4 ff ff       	call   101bb0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
  1046b8:	8b 06                	mov    (%esi),%eax
  1046ba:	3b 03                	cmp    (%ebx),%eax
  1046bc:	75 2e                	jne    1046ec <sys_link+0xdc>
  1046be:	8b 43 04             	mov    0x4(%ebx),%eax
  1046c1:	89 7c 24 04          	mov    %edi,0x4(%esp)
  1046c5:	89 34 24             	mov    %esi,(%esp)
  1046c8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1046cc:	e8 ff d2 ff ff       	call   1019d0 <dirlink>
  1046d1:	85 c0                	test   %eax,%eax
  1046d3:	78 17                	js     1046ec <sys_link+0xdc>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
  1046d5:	89 34 24             	mov    %esi,(%esp)
  1046d8:	e8 e3 d3 ff ff       	call   101ac0 <iunlockput>
  iput(ip);
  1046dd:	89 1c 24             	mov    %ebx,(%esp)
  1046e0:	e8 9b d1 ff ff       	call   101880 <iput>
  1046e5:	31 c0                	xor    %eax,%eax
  return 0;
  1046e7:	e9 4f ff ff ff       	jmp    10463b <sys_link+0x2b>

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
  ilock(dp);
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    iunlockput(dp);
  1046ec:	89 34 24             	mov    %esi,(%esp)
  1046ef:	e8 cc d3 ff ff       	call   101ac0 <iunlockput>
  iunlockput(dp);
  iput(ip);
  return 0;

bad:
  ilock(ip);
  1046f4:	89 1c 24             	mov    %ebx,(%esp)
  1046f7:	e8 b4 d4 ff ff       	call   101bb0 <ilock>
  ip->nlink--;
  1046fc:	66 83 6b 16 01       	subw   $0x1,0x16(%ebx)
  iupdate(ip);
  104701:	89 1c 24             	mov    %ebx,(%esp)
  104704:	e8 67 cd ff ff       	call   101470 <iupdate>
  iunlockput(ip);
  104709:	89 1c 24             	mov    %ebx,(%esp)
  10470c:	e8 af d3 ff ff       	call   101ac0 <iunlockput>
  104711:	83 c8 ff             	or     $0xffffffff,%eax
  return -1;
  104714:	e9 22 ff ff ff       	jmp    10463b <sys_link+0x2b>
  104719:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00104720 <sys_open>:
  return ip;
}

int
sys_open(void)
{
  104720:	55                   	push   %ebp
  104721:	89 e5                	mov    %esp,%ebp
  104723:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
  104726:	8d 45 f4             	lea    -0xc(%ebp),%eax
  return ip;
}

int
sys_open(void)
{
  104729:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  10472c:	89 75 fc             	mov    %esi,-0x4(%ebp)
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
  10472f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104733:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10473a:	e8 11 f9 ff ff       	call   104050 <argstr>
  10473f:	85 c0                	test   %eax,%eax
  104741:	79 15                	jns    104758 <sys_open+0x38>

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    if(f)
      fileclose(f);
    iunlockput(ip);
    return -1;
  104743:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  f->ip = ip;
  f->off = 0;
  f->readable = !(omode & O_WRONLY);
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
  return fd;
}
  104748:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  10474b:	8b 75 fc             	mov    -0x4(%ebp),%esi
  10474e:	89 ec                	mov    %ebp,%esp
  104750:	5d                   	pop    %ebp
  104751:	c3                   	ret    
  104752:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
  104758:	8d 45 f0             	lea    -0x10(%ebp),%eax
  10475b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10475f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104766:	e8 55 f8 ff ff       	call   103fc0 <argint>
  10476b:	85 c0                	test   %eax,%eax
  10476d:	78 d4                	js     104743 <sys_open+0x23>
    return -1;
  if(omode & O_CREATE){
  10476f:	f6 45 f1 02          	testb  $0x2,-0xf(%ebp)
  104773:	74 63                	je     1047d8 <sys_open+0xb8>
    if((ip = create(path, T_FILE, 0, 0)) == 0)
  104775:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104778:	31 c9                	xor    %ecx,%ecx
  10477a:	ba 02 00 00 00       	mov    $0x2,%edx
  10477f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104786:	e8 25 fc ff ff       	call   1043b0 <create>
  10478b:	85 c0                	test   %eax,%eax
  10478d:	89 c3                	mov    %eax,%ebx
  10478f:	74 b2                	je     104743 <sys_open+0x23>
      iunlockput(ip);
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
  104791:	e8 5a c7 ff ff       	call   100ef0 <filealloc>
  104796:	85 c0                	test   %eax,%eax
  104798:	89 c6                	mov    %eax,%esi
  10479a:	74 24                	je     1047c0 <sys_open+0xa0>
  10479c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  1047a3:	31 c0                	xor    %eax,%eax
  1047a5:	8d 76 00             	lea    0x0(%esi),%esi
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
  1047a8:	8b 4c 82 28          	mov    0x28(%edx,%eax,4),%ecx
  1047ac:	85 c9                	test   %ecx,%ecx
  1047ae:	74 58                	je     104808 <sys_open+0xe8>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
  1047b0:	83 c0 01             	add    $0x1,%eax
  1047b3:	83 f8 10             	cmp    $0x10,%eax
  1047b6:	75 f0                	jne    1047a8 <sys_open+0x88>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    if(f)
      fileclose(f);
  1047b8:	89 34 24             	mov    %esi,(%esp)
  1047bb:	e8 b0 c7 ff ff       	call   100f70 <fileclose>
    iunlockput(ip);
  1047c0:	89 1c 24             	mov    %ebx,(%esp)
  1047c3:	e8 f8 d2 ff ff       	call   101ac0 <iunlockput>
  1047c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    return -1;
  1047cd:	e9 76 ff ff ff       	jmp    104748 <sys_open+0x28>
  1047d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    return -1;
  if(omode & O_CREATE){
    if((ip = create(path, T_FILE, 0, 0)) == 0)
      return -1;
  } else {
    if((ip = namei(path)) == 0)
  1047d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1047db:	89 04 24             	mov    %eax,(%esp)
  1047de:	e8 6d d6 ff ff       	call   101e50 <namei>
  1047e3:	85 c0                	test   %eax,%eax
  1047e5:	89 c3                	mov    %eax,%ebx
  1047e7:	0f 84 56 ff ff ff    	je     104743 <sys_open+0x23>
      return -1;
    ilock(ip);
  1047ed:	89 04 24             	mov    %eax,(%esp)
  1047f0:	e8 bb d3 ff ff       	call   101bb0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
  1047f5:	66 83 7b 10 01       	cmpw   $0x1,0x10(%ebx)
  1047fa:	75 95                	jne    104791 <sys_open+0x71>
  1047fc:	8b 75 f0             	mov    -0x10(%ebp),%esi
  1047ff:	85 f6                	test   %esi,%esi
  104801:	74 8e                	je     104791 <sys_open+0x71>
  104803:	eb bb                	jmp    1047c0 <sys_open+0xa0>
  104805:	8d 76 00             	lea    0x0(%esi),%esi
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
  104808:	89 74 82 28          	mov    %esi,0x28(%edx,%eax,4)
    if(f)
      fileclose(f);
    iunlockput(ip);
    return -1;
  }
  iunlock(ip);
  10480c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10480f:	89 1c 24             	mov    %ebx,(%esp)
  104812:	e8 59 cf ff ff       	call   101770 <iunlock>

  f->type = FD_INODE;
  104817:	c7 06 02 00 00 00    	movl   $0x2,(%esi)
  f->ip = ip;
  10481d:	89 5e 10             	mov    %ebx,0x10(%esi)
  f->off = 0;
  104820:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)
  f->readable = !(omode & O_WRONLY);
  104827:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10482a:	83 f2 01             	xor    $0x1,%edx
  10482d:	83 e2 01             	and    $0x1,%edx
  104830:	88 56 08             	mov    %dl,0x8(%esi)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
  104833:	f6 45 f0 03          	testb  $0x3,-0x10(%ebp)
  104837:	0f 95 46 09          	setne  0x9(%esi)
  return fd;
  10483b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10483e:	e9 05 ff ff ff       	jmp    104748 <sys_open+0x28>
  104843:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104849:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00104850 <sys_unlink>:
  return 1;
}

int
sys_unlink(void)
{
  104850:	55                   	push   %ebp
  104851:	89 e5                	mov    %esp,%ebp
  104853:	83 ec 78             	sub    $0x78,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
  104856:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  return 1;
}

int
sys_unlink(void)
{
  104859:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  10485c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  10485f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
  104862:	89 44 24 04          	mov    %eax,0x4(%esp)
  104866:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10486d:	e8 de f7 ff ff       	call   104050 <argstr>
  104872:	85 c0                	test   %eax,%eax
  104874:	79 12                	jns    104888 <sys_unlink+0x38>
  iunlockput(dp);

  ip->nlink--;
  iupdate(ip);
  iunlockput(ip);
  return 0;
  104876:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  10487b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10487e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  104881:	8b 7d fc             	mov    -0x4(%ebp),%edi
  104884:	89 ec                	mov    %ebp,%esp
  104886:	5d                   	pop    %ebp
  104887:	c3                   	ret    
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
    return -1;
  if((dp = nameiparent(path, name)) == 0)
  104888:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10488b:	8d 5d d2             	lea    -0x2e(%ebp),%ebx
  10488e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  104892:	89 04 24             	mov    %eax,(%esp)
  104895:	e8 96 d5 ff ff       	call   101e30 <nameiparent>
  10489a:	85 c0                	test   %eax,%eax
  10489c:	89 45 a4             	mov    %eax,-0x5c(%ebp)
  10489f:	74 d5                	je     104876 <sys_unlink+0x26>
    return -1;
  ilock(dp);
  1048a1:	89 04 24             	mov    %eax,(%esp)
  1048a4:	e8 07 d3 ff ff       	call   101bb0 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0){
  1048a9:	c7 44 24 04 6c 6c 10 	movl   $0x106c6c,0x4(%esp)
  1048b0:	00 
  1048b1:	89 1c 24             	mov    %ebx,(%esp)
  1048b4:	e8 87 cd ff ff       	call   101640 <namecmp>
  1048b9:	85 c0                	test   %eax,%eax
  1048bb:	0f 84 a4 00 00 00    	je     104965 <sys_unlink+0x115>
  1048c1:	c7 44 24 04 6b 6c 10 	movl   $0x106c6b,0x4(%esp)
  1048c8:	00 
  1048c9:	89 1c 24             	mov    %ebx,(%esp)
  1048cc:	e8 6f cd ff ff       	call   101640 <namecmp>
  1048d1:	85 c0                	test   %eax,%eax
  1048d3:	0f 84 8c 00 00 00    	je     104965 <sys_unlink+0x115>
    iunlockput(dp);
    return -1;
  }

  if((ip = dirlookup(dp, name, &off)) == 0){
  1048d9:	8d 45 e0             	lea    -0x20(%ebp),%eax
  1048dc:	89 44 24 08          	mov    %eax,0x8(%esp)
  1048e0:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1048e3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  1048e7:	89 04 24             	mov    %eax,(%esp)
  1048ea:	e8 81 cd ff ff       	call   101670 <dirlookup>
  1048ef:	85 c0                	test   %eax,%eax
  1048f1:	89 c6                	mov    %eax,%esi
  1048f3:	74 70                	je     104965 <sys_unlink+0x115>
    iunlockput(dp);
    return -1;
  }
  ilock(ip);
  1048f5:	89 04 24             	mov    %eax,(%esp)
  1048f8:	e8 b3 d2 ff ff       	call   101bb0 <ilock>

  if(ip->nlink < 1)
  1048fd:	66 83 7e 16 00       	cmpw   $0x0,0x16(%esi)
  104902:	0f 8e 0e 01 00 00    	jle    104a16 <sys_unlink+0x1c6>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
  104908:	66 83 7e 10 01       	cmpw   $0x1,0x10(%esi)
  10490d:	75 71                	jne    104980 <sys_unlink+0x130>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
  10490f:	83 7e 18 20          	cmpl   $0x20,0x18(%esi)
  104913:	76 6b                	jbe    104980 <sys_unlink+0x130>
  104915:	8d 7d b2             	lea    -0x4e(%ebp),%edi
  104918:	bb 20 00 00 00       	mov    $0x20,%ebx
  10491d:	8d 76 00             	lea    0x0(%esi),%esi
  104920:	eb 0e                	jmp    104930 <sys_unlink+0xe0>
  104922:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104928:	83 c3 10             	add    $0x10,%ebx
  10492b:	3b 5e 18             	cmp    0x18(%esi),%ebx
  10492e:	73 50                	jae    104980 <sys_unlink+0x130>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
  104930:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  104937:	00 
  104938:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  10493c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  104940:	89 34 24             	mov    %esi,(%esp)
  104943:	e8 18 ca ff ff       	call   101360 <readi>
  104948:	83 f8 10             	cmp    $0x10,%eax
  10494b:	0f 85 ad 00 00 00    	jne    1049fe <sys_unlink+0x1ae>
      panic("isdirempty: readi");
    if(de.inum != 0)
  104951:	66 83 7d b2 00       	cmpw   $0x0,-0x4e(%ebp)
  104956:	74 d0                	je     104928 <sys_unlink+0xd8>
  ilock(ip);

  if(ip->nlink < 1)
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    iunlockput(ip);
  104958:	89 34 24             	mov    %esi,(%esp)
  10495b:	90                   	nop
  10495c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  104960:	e8 5b d1 ff ff       	call   101ac0 <iunlockput>
    iunlockput(dp);
  104965:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  104968:	89 04 24             	mov    %eax,(%esp)
  10496b:	e8 50 d1 ff ff       	call   101ac0 <iunlockput>
  104970:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    return -1;
  104975:	e9 01 ff ff ff       	jmp    10487b <sys_unlink+0x2b>
  10497a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  }

  memset(&de, 0, sizeof(de));
  104980:	8d 5d c2             	lea    -0x3e(%ebp),%ebx
  104983:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  10498a:	00 
  10498b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104992:	00 
  104993:	89 1c 24             	mov    %ebx,(%esp)
  104996:	e8 85 f3 ff ff       	call   103d20 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
  10499b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10499e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1049a5:	00 
  1049a6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  1049aa:	89 44 24 08          	mov    %eax,0x8(%esp)
  1049ae:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1049b1:	89 04 24             	mov    %eax,(%esp)
  1049b4:	e8 47 cb ff ff       	call   101500 <writei>
  1049b9:	83 f8 10             	cmp    $0x10,%eax
  1049bc:	75 4c                	jne    104a0a <sys_unlink+0x1ba>
    panic("unlink: writei");
  if(ip->type == T_DIR){
  1049be:	66 83 7e 10 01       	cmpw   $0x1,0x10(%esi)
  1049c3:	74 27                	je     1049ec <sys_unlink+0x19c>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
  1049c5:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1049c8:	89 04 24             	mov    %eax,(%esp)
  1049cb:	e8 f0 d0 ff ff       	call   101ac0 <iunlockput>

  ip->nlink--;
  1049d0:	66 83 6e 16 01       	subw   $0x1,0x16(%esi)
  iupdate(ip);
  1049d5:	89 34 24             	mov    %esi,(%esp)
  1049d8:	e8 93 ca ff ff       	call   101470 <iupdate>
  iunlockput(ip);
  1049dd:	89 34 24             	mov    %esi,(%esp)
  1049e0:	e8 db d0 ff ff       	call   101ac0 <iunlockput>
  1049e5:	31 c0                	xor    %eax,%eax
  return 0;
  1049e7:	e9 8f fe ff ff       	jmp    10487b <sys_unlink+0x2b>

  memset(&de, 0, sizeof(de));
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
    panic("unlink: writei");
  if(ip->type == T_DIR){
    dp->nlink--;
  1049ec:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1049ef:	66 83 68 16 01       	subw   $0x1,0x16(%eax)
    iupdate(dp);
  1049f4:	89 04 24             	mov    %eax,(%esp)
  1049f7:	e8 74 ca ff ff       	call   101470 <iupdate>
  1049fc:	eb c7                	jmp    1049c5 <sys_unlink+0x175>
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
  1049fe:	c7 04 24 9c 6c 10 00 	movl   $0x106c9c,(%esp)
  104a05:	e8 16 bf ff ff       	call   100920 <panic>
    return -1;
  }

  memset(&de, 0, sizeof(de));
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
    panic("unlink: writei");
  104a0a:	c7 04 24 ae 6c 10 00 	movl   $0x106cae,(%esp)
  104a11:	e8 0a bf ff ff       	call   100920 <panic>
    return -1;
  }
  ilock(ip);

  if(ip->nlink < 1)
    panic("unlink: nlink < 1");
  104a16:	c7 04 24 8a 6c 10 00 	movl   $0x106c8a,(%esp)
  104a1d:	e8 fe be ff ff       	call   100920 <panic>
  104a22:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  104a29:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00104a30 <T.67>:
#include "fcntl.h"

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
  104a30:	55                   	push   %ebp
  104a31:	89 e5                	mov    %esp,%ebp
  104a33:	83 ec 28             	sub    $0x28,%esp
  104a36:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  104a39:	89 c3                	mov    %eax,%ebx
{
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
  104a3b:	8d 45 f4             	lea    -0xc(%ebp),%eax
#include "fcntl.h"

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
  104a3e:	89 75 fc             	mov    %esi,-0x4(%ebp)
  104a41:	89 d6                	mov    %edx,%esi
{
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
  104a43:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a47:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104a4e:	e8 6d f5 ff ff       	call   103fc0 <argint>
  104a53:	85 c0                	test   %eax,%eax
  104a55:	79 11                	jns    104a68 <T.67+0x38>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
    return -1;
  if(pfd)
    *pfd = fd;
  if(pf)
    *pf = f;
  104a57:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  return 0;
}
  104a5c:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  104a5f:	8b 75 fc             	mov    -0x4(%ebp),%esi
  104a62:	89 ec                	mov    %ebp,%esp
  104a64:	5d                   	pop    %ebp
  104a65:	c3                   	ret    
  104a66:	66 90                	xchg   %ax,%ax
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
  104a68:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104a6b:	83 f8 0f             	cmp    $0xf,%eax
  104a6e:	77 e7                	ja     104a57 <T.67+0x27>
  104a70:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  104a77:	8b 54 82 28          	mov    0x28(%edx,%eax,4),%edx
  104a7b:	85 d2                	test   %edx,%edx
  104a7d:	74 d8                	je     104a57 <T.67+0x27>
    return -1;
  if(pfd)
  104a7f:	85 db                	test   %ebx,%ebx
  104a81:	74 02                	je     104a85 <T.67+0x55>
    *pfd = fd;
  104a83:	89 03                	mov    %eax,(%ebx)
  if(pf)
  104a85:	31 c0                	xor    %eax,%eax
  104a87:	85 f6                	test   %esi,%esi
  104a89:	74 d1                	je     104a5c <T.67+0x2c>
    *pf = f;
  104a8b:	89 16                	mov    %edx,(%esi)
  104a8d:	eb cd                	jmp    104a5c <T.67+0x2c>
  104a8f:	90                   	nop

00104a90 <sys_dup>:
  return -1;
}

int
sys_dup(void)
{
  104a90:	55                   	push   %ebp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
  104a91:	31 c0                	xor    %eax,%eax
  return -1;
}

int
sys_dup(void)
{
  104a93:	89 e5                	mov    %esp,%ebp
  104a95:	53                   	push   %ebx
  104a96:	83 ec 24             	sub    $0x24,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
  104a99:	8d 55 f4             	lea    -0xc(%ebp),%edx
  104a9c:	e8 8f ff ff ff       	call   104a30 <T.67>
  104aa1:	85 c0                	test   %eax,%eax
  104aa3:	79 13                	jns    104ab8 <sys_dup+0x28>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
  104aa5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
    return -1;
  if((fd=fdalloc(f)) < 0)
    return -1;
  filedup(f);
  return fd;
}
  104aaa:	89 d8                	mov    %ebx,%eax
  104aac:	83 c4 24             	add    $0x24,%esp
  104aaf:	5b                   	pop    %ebx
  104ab0:	5d                   	pop    %ebp
  104ab1:	c3                   	ret    
  104ab2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
    return -1;
  if((fd=fdalloc(f)) < 0)
  104ab8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104abb:	31 db                	xor    %ebx,%ebx
  104abd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104ac3:	eb 0b                	jmp    104ad0 <sys_dup+0x40>
  104ac5:	8d 76 00             	lea    0x0(%esi),%esi
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
  104ac8:	83 c3 01             	add    $0x1,%ebx
  104acb:	83 fb 10             	cmp    $0x10,%ebx
  104ace:	74 d5                	je     104aa5 <sys_dup+0x15>
    if(proc->ofile[fd] == 0){
  104ad0:	8b 4c 98 28          	mov    0x28(%eax,%ebx,4),%ecx
  104ad4:	85 c9                	test   %ecx,%ecx
  104ad6:	75 f0                	jne    104ac8 <sys_dup+0x38>
      proc->ofile[fd] = f;
  104ad8:	89 54 98 28          	mov    %edx,0x28(%eax,%ebx,4)
  
  if(argfd(0, 0, &f) < 0)
    return -1;
  if((fd=fdalloc(f)) < 0)
    return -1;
  filedup(f);
  104adc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104adf:	89 04 24             	mov    %eax,(%esp)
  104ae2:	e8 b9 c3 ff ff       	call   100ea0 <filedup>
  return fd;
  104ae7:	eb c1                	jmp    104aaa <sys_dup+0x1a>
  104ae9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00104af0 <sys_read>:
}

int
sys_read(void)
{
  104af0:	55                   	push   %ebp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104af1:	31 c0                	xor    %eax,%eax
  return fd;
}

int
sys_read(void)
{
  104af3:	89 e5                	mov    %esp,%ebp
  104af5:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104af8:	8d 55 f4             	lea    -0xc(%ebp),%edx
  104afb:	e8 30 ff ff ff       	call   104a30 <T.67>
  104b00:	85 c0                	test   %eax,%eax
  104b02:	79 0c                	jns    104b10 <sys_read+0x20>
    return -1;
  return fileread(f, p, n);
  104b04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104b09:	c9                   	leave  
  104b0a:	c3                   	ret    
  104b0b:	90                   	nop
  104b0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104b10:	8d 45 f0             	lea    -0x10(%ebp),%eax
  104b13:	89 44 24 04          	mov    %eax,0x4(%esp)
  104b17:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  104b1e:	e8 9d f4 ff ff       	call   103fc0 <argint>
  104b23:	85 c0                	test   %eax,%eax
  104b25:	78 dd                	js     104b04 <sys_read+0x14>
  104b27:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104b2a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104b31:	89 44 24 08          	mov    %eax,0x8(%esp)
  104b35:	8d 45 ec             	lea    -0x14(%ebp),%eax
  104b38:	89 44 24 04          	mov    %eax,0x4(%esp)
  104b3c:	e8 bf f4 ff ff       	call   104000 <argptr>
  104b41:	85 c0                	test   %eax,%eax
  104b43:	78 bf                	js     104b04 <sys_read+0x14>
    return -1;
  return fileread(f, p, n);
  104b45:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104b48:	89 44 24 08          	mov    %eax,0x8(%esp)
  104b4c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104b4f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104b53:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104b56:	89 04 24             	mov    %eax,(%esp)
  104b59:	e8 42 c2 ff ff       	call   100da0 <fileread>
}
  104b5e:	c9                   	leave  
  104b5f:	c3                   	ret    

00104b60 <sys_write>:

int
sys_write(void)
{
  104b60:	55                   	push   %ebp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104b61:	31 c0                	xor    %eax,%eax
  return fileread(f, p, n);
}

int
sys_write(void)
{
  104b63:	89 e5                	mov    %esp,%ebp
  104b65:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104b68:	8d 55 f4             	lea    -0xc(%ebp),%edx
  104b6b:	e8 c0 fe ff ff       	call   104a30 <T.67>
  104b70:	85 c0                	test   %eax,%eax
  104b72:	79 0c                	jns    104b80 <sys_write+0x20>
    return -1;
  return filewrite(f, p, n);
  104b74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104b79:	c9                   	leave  
  104b7a:	c3                   	ret    
  104b7b:	90                   	nop
  104b7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
{
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
  104b80:	8d 45 f0             	lea    -0x10(%ebp),%eax
  104b83:	89 44 24 04          	mov    %eax,0x4(%esp)
  104b87:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  104b8e:	e8 2d f4 ff ff       	call   103fc0 <argint>
  104b93:	85 c0                	test   %eax,%eax
  104b95:	78 dd                	js     104b74 <sys_write+0x14>
  104b97:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104b9a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104ba1:	89 44 24 08          	mov    %eax,0x8(%esp)
  104ba5:	8d 45 ec             	lea    -0x14(%ebp),%eax
  104ba8:	89 44 24 04          	mov    %eax,0x4(%esp)
  104bac:	e8 4f f4 ff ff       	call   104000 <argptr>
  104bb1:	85 c0                	test   %eax,%eax
  104bb3:	78 bf                	js     104b74 <sys_write+0x14>
    return -1;
  return filewrite(f, p, n);
  104bb5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104bb8:	89 44 24 08          	mov    %eax,0x8(%esp)
  104bbc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104bbf:	89 44 24 04          	mov    %eax,0x4(%esp)
  104bc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104bc6:	89 04 24             	mov    %eax,(%esp)
  104bc9:	e8 22 c1 ff ff       	call   100cf0 <filewrite>
}
  104bce:	c9                   	leave  
  104bcf:	c3                   	ret    

00104bd0 <sys_fstat>:
  return 0;
}

int
sys_fstat(void)
{
  104bd0:	55                   	push   %ebp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
  104bd1:	31 c0                	xor    %eax,%eax
  return 0;
}

int
sys_fstat(void)
{
  104bd3:	89 e5                	mov    %esp,%ebp
  104bd5:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
  104bd8:	8d 55 f4             	lea    -0xc(%ebp),%edx
  104bdb:	e8 50 fe ff ff       	call   104a30 <T.67>
  104be0:	85 c0                	test   %eax,%eax
  104be2:	79 0c                	jns    104bf0 <sys_fstat+0x20>
    return -1;
  return filestat(f, st);
  104be4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104be9:	c9                   	leave  
  104bea:	c3                   	ret    
  104beb:	90                   	nop
  104bec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
sys_fstat(void)
{
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
  104bf0:	8d 45 f0             	lea    -0x10(%ebp),%eax
  104bf3:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
  104bfa:	00 
  104bfb:	89 44 24 04          	mov    %eax,0x4(%esp)
  104bff:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104c06:	e8 f5 f3 ff ff       	call   104000 <argptr>
  104c0b:	85 c0                	test   %eax,%eax
  104c0d:	78 d5                	js     104be4 <sys_fstat+0x14>
    return -1;
  return filestat(f, st);
  104c0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104c12:	89 44 24 04          	mov    %eax,0x4(%esp)
  104c16:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104c19:	89 04 24             	mov    %eax,(%esp)
  104c1c:	e8 2f c2 ff ff       	call   100e50 <filestat>
}
  104c21:	c9                   	leave  
  104c22:	c3                   	ret    
  104c23:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104c29:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00104c30 <sys_close>:
  return filewrite(f, p, n);
}

int
sys_close(void)
{
  104c30:	55                   	push   %ebp
  104c31:	89 e5                	mov    %esp,%ebp
  104c33:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
  104c36:	8d 55 f0             	lea    -0x10(%ebp),%edx
  104c39:	8d 45 f4             	lea    -0xc(%ebp),%eax
  104c3c:	e8 ef fd ff ff       	call   104a30 <T.67>
  104c41:	89 c2                	mov    %eax,%edx
  104c43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104c48:	85 d2                	test   %edx,%edx
  104c4a:	78 1e                	js     104c6a <sys_close+0x3a>
    return -1;
  proc->ofile[fd] = 0;
  104c4c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104c52:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104c55:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
  104c5c:	00 
  fileclose(f);
  104c5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104c60:	89 04 24             	mov    %eax,(%esp)
  104c63:	e8 08 c3 ff ff       	call   100f70 <fileclose>
  104c68:	31 c0                	xor    %eax,%eax
  return 0;
}
  104c6a:	c9                   	leave  
  104c6b:	c3                   	ret    
  104c6c:	90                   	nop
  104c6d:	90                   	nop
  104c6e:	90                   	nop
  104c6f:	90                   	nop

00104c70 <sys_getpid>:
}

int
sys_getpid(void)
{
  return proc->pid;
  104c70:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  return kill(pid);
}

int
sys_getpid(void)
{
  104c76:	55                   	push   %ebp
  104c77:	89 e5                	mov    %esp,%ebp
  return proc->pid;
}
  104c79:	5d                   	pop    %ebp
}

int
sys_getpid(void)
{
  return proc->pid;
  104c7a:	8b 40 10             	mov    0x10(%eax),%eax
}
  104c7d:	c3                   	ret    
  104c7e:	66 90                	xchg   %ax,%ax

00104c80 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since boot.
int
sys_uptime(void)
{
  104c80:	55                   	push   %ebp
  104c81:	89 e5                	mov    %esp,%ebp
  104c83:	53                   	push   %ebx
  104c84:	83 ec 14             	sub    $0x14,%esp
  uint xticks;
  
  acquire(&tickslock);
  104c87:	c7 04 24 60 e0 10 00 	movl   $0x10e060,(%esp)
  104c8e:	e8 ed ef ff ff       	call   103c80 <acquire>
  xticks = ticks;
  104c93:	8b 1d a0 e8 10 00    	mov    0x10e8a0,%ebx
  release(&tickslock);
  104c99:	c7 04 24 60 e0 10 00 	movl   $0x10e060,(%esp)
  104ca0:	e8 8b ef ff ff       	call   103c30 <release>
  return xticks;
}
  104ca5:	83 c4 14             	add    $0x14,%esp
  104ca8:	89 d8                	mov    %ebx,%eax
  104caa:	5b                   	pop    %ebx
  104cab:	5d                   	pop    %ebp
  104cac:	c3                   	ret    
  104cad:	8d 76 00             	lea    0x0(%esi),%esi

00104cb0 <sys_sleep>:
  return addr;
}

int
sys_sleep(void)
{
  104cb0:	55                   	push   %ebp
  104cb1:	89 e5                	mov    %esp,%ebp
  104cb3:	53                   	push   %ebx
  104cb4:	83 ec 24             	sub    $0x24,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
  104cb7:	8d 45 f4             	lea    -0xc(%ebp),%eax
  104cba:	89 44 24 04          	mov    %eax,0x4(%esp)
  104cbe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104cc5:	e8 f6 f2 ff ff       	call   103fc0 <argint>
  104cca:	89 c2                	mov    %eax,%edx
  104ccc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104cd1:	85 d2                	test   %edx,%edx
  104cd3:	78 59                	js     104d2e <sys_sleep+0x7e>
    return -1;
  acquire(&tickslock);
  104cd5:	c7 04 24 60 e0 10 00 	movl   $0x10e060,(%esp)
  104cdc:	e8 9f ef ff ff       	call   103c80 <acquire>
  ticks0 = ticks;
  while(ticks - ticks0 < n){
  104ce1:	8b 55 f4             	mov    -0xc(%ebp),%edx
  uint ticks0;
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  104ce4:	8b 1d a0 e8 10 00    	mov    0x10e8a0,%ebx
  while(ticks - ticks0 < n){
  104cea:	85 d2                	test   %edx,%edx
  104cec:	75 22                	jne    104d10 <sys_sleep+0x60>
  104cee:	eb 48                	jmp    104d38 <sys_sleep+0x88>
    if(proc->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  104cf0:	c7 44 24 04 60 e0 10 	movl   $0x10e060,0x4(%esp)
  104cf7:	00 
  104cf8:	c7 04 24 a0 e8 10 00 	movl   $0x10e8a0,(%esp)
  104cff:	e8 4c e5 ff ff       	call   103250 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
  104d04:	a1 a0 e8 10 00       	mov    0x10e8a0,%eax
  104d09:	29 d8                	sub    %ebx,%eax
  104d0b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104d0e:	73 28                	jae    104d38 <sys_sleep+0x88>
    if(proc->killed){
  104d10:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104d16:	8b 40 24             	mov    0x24(%eax),%eax
  104d19:	85 c0                	test   %eax,%eax
  104d1b:	74 d3                	je     104cf0 <sys_sleep+0x40>
      release(&tickslock);
  104d1d:	c7 04 24 60 e0 10 00 	movl   $0x10e060,(%esp)
  104d24:	e8 07 ef ff ff       	call   103c30 <release>
  104d29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}
  104d2e:	83 c4 24             	add    $0x24,%esp
  104d31:	5b                   	pop    %ebx
  104d32:	5d                   	pop    %ebp
  104d33:	c3                   	ret    
  104d34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  104d38:	c7 04 24 60 e0 10 00 	movl   $0x10e060,(%esp)
  104d3f:	e8 ec ee ff ff       	call   103c30 <release>
  return 0;
}
  104d44:	83 c4 24             	add    $0x24,%esp
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  104d47:	31 c0                	xor    %eax,%eax
  return 0;
}
  104d49:	5b                   	pop    %ebx
  104d4a:	5d                   	pop    %ebp
  104d4b:	c3                   	ret    
  104d4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00104d50 <sys_sbrk>:
  return proc->pid;
}

int
sys_sbrk(void)
{
  104d50:	55                   	push   %ebp
  104d51:	89 e5                	mov    %esp,%ebp
  104d53:	53                   	push   %ebx
  104d54:	83 ec 24             	sub    $0x24,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
  104d57:	8d 45 f4             	lea    -0xc(%ebp),%eax
  104d5a:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d5e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104d65:	e8 56 f2 ff ff       	call   103fc0 <argint>
  104d6a:	85 c0                	test   %eax,%eax
  104d6c:	79 12                	jns    104d80 <sys_sbrk+0x30>
    return -1;
  addr = proc->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
  104d6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  104d73:	83 c4 24             	add    $0x24,%esp
  104d76:	5b                   	pop    %ebx
  104d77:	5d                   	pop    %ebp
  104d78:	c3                   	ret    
  104d79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = proc->sz;
  104d80:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104d86:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
  104d88:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104d8b:	89 04 24             	mov    %eax,(%esp)
  104d8e:	e8 cd eb ff ff       	call   103960 <growproc>
  104d93:	89 c2                	mov    %eax,%edx
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = proc->sz;
  104d95:	89 d8                	mov    %ebx,%eax
  if(growproc(n) < 0)
  104d97:	85 d2                	test   %edx,%edx
  104d99:	79 d8                	jns    104d73 <sys_sbrk+0x23>
  104d9b:	eb d1                	jmp    104d6e <sys_sbrk+0x1e>
  104d9d:	8d 76 00             	lea    0x0(%esi),%esi

00104da0 <sys_kill>:
  return wait();
}

int
sys_kill(void)
{
  104da0:	55                   	push   %ebp
  104da1:	89 e5                	mov    %esp,%ebp
  104da3:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
  104da6:	8d 45 f4             	lea    -0xc(%ebp),%eax
  104da9:	89 44 24 04          	mov    %eax,0x4(%esp)
  104dad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104db4:	e8 07 f2 ff ff       	call   103fc0 <argint>
  104db9:	89 c2                	mov    %eax,%edx
  104dbb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104dc0:	85 d2                	test   %edx,%edx
  104dc2:	78 0b                	js     104dcf <sys_kill+0x2f>
    return -1;
  return kill(pid);
  104dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104dc7:	89 04 24             	mov    %eax,(%esp)
  104dca:	e8 d1 e2 ff ff       	call   1030a0 <kill>
}
  104dcf:	c9                   	leave  
  104dd0:	c3                   	ret    
  104dd1:	eb 0d                	jmp    104de0 <sys_wait>
  104dd3:	90                   	nop
  104dd4:	90                   	nop
  104dd5:	90                   	nop
  104dd6:	90                   	nop
  104dd7:	90                   	nop
  104dd8:	90                   	nop
  104dd9:	90                   	nop
  104dda:	90                   	nop
  104ddb:	90                   	nop
  104ddc:	90                   	nop
  104ddd:	90                   	nop
  104dde:	90                   	nop
  104ddf:	90                   	nop

00104de0 <sys_wait>:
  return 0;  // not reached
}

int
sys_wait(void)
{
  104de0:	55                   	push   %ebp
  104de1:	89 e5                	mov    %esp,%ebp
  104de3:	83 ec 08             	sub    $0x8,%esp
  return wait();
}
  104de6:	c9                   	leave  
}

int
sys_wait(void)
{
  return wait();
  104de7:	e9 14 e6 ff ff       	jmp    103400 <wait>
  104dec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00104df0 <sys_exit>:
  return clone();
}

int
sys_exit(void)
{
  104df0:	55                   	push   %ebp
  104df1:	89 e5                	mov    %esp,%ebp
  104df3:	83 ec 08             	sub    $0x8,%esp
  exit();
  104df6:	e8 05 e7 ff ff       	call   103500 <exit>
  return 0;  // not reached
}
  104dfb:	31 c0                	xor    %eax,%eax
  104dfd:	c9                   	leave  
  104dfe:	c3                   	ret    
  104dff:	90                   	nop

00104e00 <sys_clone>:
  return fork();
}

int
sys_clone(void)
{
  104e00:	55                   	push   %ebp
  104e01:	89 e5                	mov    %esp,%ebp
  104e03:	83 ec 08             	sub    $0x8,%esp
  return clone();
}
  104e06:	c9                   	leave  
}

int
sys_clone(void)
{
  return clone();
  104e07:	e9 04 e9 ff ff       	jmp    103710 <clone>
  104e0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00104e10 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
  104e10:	55                   	push   %ebp
  104e11:	89 e5                	mov    %esp,%ebp
  104e13:	83 ec 08             	sub    $0x8,%esp
  return fork();
}
  104e16:	c9                   	leave  
#include "proc.h"

int
sys_fork(void)
{
  return fork();
  104e17:	e9 44 ea ff ff       	jmp    103860 <fork>
  104e1c:	90                   	nop
  104e1d:	90                   	nop
  104e1e:	90                   	nop
  104e1f:	90                   	nop

00104e20 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
  104e20:	55                   	push   %ebp
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  104e21:	ba 43 00 00 00       	mov    $0x43,%edx
  104e26:	89 e5                	mov    %esp,%ebp
  104e28:	83 ec 18             	sub    $0x18,%esp
  104e2b:	b8 34 00 00 00       	mov    $0x34,%eax
  104e30:	ee                   	out    %al,(%dx)
  104e31:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
  104e36:	b2 40                	mov    $0x40,%dl
  104e38:	ee                   	out    %al,(%dx)
  104e39:	b8 2e 00 00 00       	mov    $0x2e,%eax
  104e3e:	ee                   	out    %al,(%dx)
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
  picenable(IRQ_TIMER);
  104e3f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104e46:	e8 45 dd ff ff       	call   102b90 <picenable>
}
  104e4b:	c9                   	leave  
  104e4c:	c3                   	ret    
  104e4d:	90                   	nop
  104e4e:	90                   	nop
  104e4f:	90                   	nop

00104e50 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
  104e50:	1e                   	push   %ds
  pushl %es
  104e51:	06                   	push   %es
  pushl %fs
  104e52:	0f a0                	push   %fs
  pushl %gs
  104e54:	0f a8                	push   %gs
  pushal
  104e56:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
  104e57:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
  104e5b:	8e d8                	mov    %eax,%ds
  movw %ax, %es
  104e5d:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
  104e5f:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
  104e63:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
  104e65:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
  104e67:	54                   	push   %esp
  call trap
  104e68:	e8 43 00 00 00       	call   104eb0 <trap>
  addl $4, %esp
  104e6d:	83 c4 04             	add    $0x4,%esp

00104e70 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
  104e70:	61                   	popa   
  popl %gs
  104e71:	0f a9                	pop    %gs
  popl %fs
  104e73:	0f a1                	pop    %fs
  popl %es
  104e75:	07                   	pop    %es
  popl %ds
  104e76:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
  104e77:	83 c4 08             	add    $0x8,%esp
  iret
  104e7a:	cf                   	iret   
  104e7b:	90                   	nop
  104e7c:	90                   	nop
  104e7d:	90                   	nop
  104e7e:	90                   	nop
  104e7f:	90                   	nop

00104e80 <idtinit>:
  initlock(&tickslock, "time");
}

void
idtinit(void)
{
  104e80:	55                   	push   %ebp
lidt(struct gatedesc *p, int size)
{
  volatile ushort pd[3];

  pd[0] = size-1;
  pd[1] = (uint)p;
  104e81:	b8 a0 e0 10 00       	mov    $0x10e0a0,%eax
  104e86:	89 e5                	mov    %esp,%ebp
  104e88:	83 ec 10             	sub    $0x10,%esp
static inline void
lidt(struct gatedesc *p, int size)
{
  volatile ushort pd[3];

  pd[0] = size-1;
  104e8b:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
  104e91:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
  104e95:	c1 e8 10             	shr    $0x10,%eax
  104e98:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
  104e9c:	8d 45 fa             	lea    -0x6(%ebp),%eax
  104e9f:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
  104ea2:	c9                   	leave  
  104ea3:	c3                   	ret    
  104ea4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104eaa:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

00104eb0 <trap>:

void
trap(struct trapframe *tf)
{
  104eb0:	55                   	push   %ebp
  104eb1:	89 e5                	mov    %esp,%ebp
  104eb3:	56                   	push   %esi
  104eb4:	53                   	push   %ebx
  104eb5:	83 ec 20             	sub    $0x20,%esp
  104eb8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
  104ebb:	8b 43 30             	mov    0x30(%ebx),%eax
  104ebe:	83 f8 40             	cmp    $0x40,%eax
  104ec1:	0f 84 c9 00 00 00    	je     104f90 <trap+0xe0>
    if(proc->killed)
      exit();
    return;
  }

  switch(tf->trapno){
  104ec7:	8d 50 e0             	lea    -0x20(%eax),%edx
  104eca:	83 fa 1f             	cmp    $0x1f,%edx
  104ecd:	0f 86 b5 00 00 00    	jbe    104f88 <trap+0xd8>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
    break;
   
  default:
    if(proc == 0 || (tf->cs&3) == 0){
  104ed3:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
  104eda:	85 d2                	test   %edx,%edx
  104edc:	0f 84 f6 01 00 00    	je     1050d8 <trap+0x228>
  104ee2:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
  104ee6:	0f 84 ec 01 00 00    	je     1050d8 <trap+0x228>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
  104eec:	0f 20 d6             	mov    %cr2,%esi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
  104eef:	8b 4a 10             	mov    0x10(%edx),%ecx
  104ef2:	83 c2 6c             	add    $0x6c,%edx
  104ef5:	89 74 24 1c          	mov    %esi,0x1c(%esp)
  104ef9:	8b 73 38             	mov    0x38(%ebx),%esi
  104efc:	89 74 24 18          	mov    %esi,0x18(%esp)
  104f00:	65 8b 35 00 00 00 00 	mov    %gs:0x0,%esi
  104f07:	0f b6 36             	movzbl (%esi),%esi
  104f0a:	89 74 24 14          	mov    %esi,0x14(%esp)
  104f0e:	8b 73 34             	mov    0x34(%ebx),%esi
  104f11:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104f15:	89 54 24 08          	mov    %edx,0x8(%esp)
  104f19:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  104f1d:	89 74 24 10          	mov    %esi,0x10(%esp)
  104f21:	c7 04 24 18 6d 10 00 	movl   $0x106d18,(%esp)
  104f28:	e8 03 b6 ff ff       	call   100530 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
  104f2d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104f33:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
  104f3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
  104f40:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104f46:	85 c0                	test   %eax,%eax
  104f48:	74 34                	je     104f7e <trap+0xce>
  104f4a:	8b 50 24             	mov    0x24(%eax),%edx
  104f4d:	85 d2                	test   %edx,%edx
  104f4f:	74 10                	je     104f61 <trap+0xb1>
  104f51:	0f b7 53 3c          	movzwl 0x3c(%ebx),%edx
  104f55:	83 e2 03             	and    $0x3,%edx
  104f58:	83 fa 03             	cmp    $0x3,%edx
  104f5b:	0f 84 5f 01 00 00    	je     1050c0 <trap+0x210>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
  104f61:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
  104f65:	0f 84 2d 01 00 00    	je     105098 <trap+0x1e8>
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
  104f6b:	8b 40 24             	mov    0x24(%eax),%eax
  104f6e:	85 c0                	test   %eax,%eax
  104f70:	74 0c                	je     104f7e <trap+0xce>
  104f72:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
  104f76:	83 e0 03             	and    $0x3,%eax
  104f79:	83 f8 03             	cmp    $0x3,%eax
  104f7c:	74 34                	je     104fb2 <trap+0x102>
    exit();
}
  104f7e:	83 c4 20             	add    $0x20,%esp
  104f81:	5b                   	pop    %ebx
  104f82:	5e                   	pop    %esi
  104f83:	5d                   	pop    %ebp
  104f84:	c3                   	ret    
  104f85:	8d 76 00             	lea    0x0(%esi),%esi
    if(proc->killed)
      exit();
    return;
  }

  switch(tf->trapno){
  104f88:	ff 24 95 68 6d 10 00 	jmp    *0x106d68(,%edx,4)
  104f8f:	90                   	nop

void
trap(struct trapframe *tf)
{
  if(tf->trapno == T_SYSCALL){
    if(proc->killed)
  104f90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104f96:	8b 70 24             	mov    0x24(%eax),%esi
  104f99:	85 f6                	test   %esi,%esi
  104f9b:	75 23                	jne    104fc0 <trap+0x110>
      exit();
    proc->tf = tf;
  104f9d:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
  104fa0:	e8 1b f1 ff ff       	call   1040c0 <syscall>
    if(proc->killed)
  104fa5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104fab:	8b 48 24             	mov    0x24(%eax),%ecx
  104fae:	85 c9                	test   %ecx,%ecx
  104fb0:	74 cc                	je     104f7e <trap+0xce>
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
  104fb2:	83 c4 20             	add    $0x20,%esp
  104fb5:	5b                   	pop    %ebx
  104fb6:	5e                   	pop    %esi
  104fb7:	5d                   	pop    %ebp
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
  104fb8:	e9 43 e5 ff ff       	jmp    103500 <exit>
  104fbd:	8d 76 00             	lea    0x0(%esi),%esi
void
trap(struct trapframe *tf)
{
  if(tf->trapno == T_SYSCALL){
    if(proc->killed)
      exit();
  104fc0:	e8 3b e5 ff ff       	call   103500 <exit>
  104fc5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  104fcb:	eb d0                	jmp    104f9d <trap+0xed>
  104fcd:	8d 76 00             	lea    0x0(%esi),%esi
      release(&tickslock);
    }
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE:
    ideintr();
  104fd0:	e8 3b d0 ff ff       	call   102010 <ideintr>
    lapiceoi();
  104fd5:	e8 76 d4 ff ff       	call   102450 <lapiceoi>
    break;
  104fda:	e9 61 ff ff ff       	jmp    104f40 <trap+0x90>
  104fdf:	90                   	nop
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
  104fe0:	8b 43 38             	mov    0x38(%ebx),%eax
  104fe3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104fe7:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
  104feb:	89 44 24 08          	mov    %eax,0x8(%esp)
  104fef:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  104ff5:	0f b6 00             	movzbl (%eax),%eax
  104ff8:	c7 04 24 c0 6c 10 00 	movl   $0x106cc0,(%esp)
  104fff:	89 44 24 04          	mov    %eax,0x4(%esp)
  105003:	e8 28 b5 ff ff       	call   100530 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
  105008:	e8 43 d4 ff ff       	call   102450 <lapiceoi>
    break;
  10500d:	e9 2e ff ff ff       	jmp    104f40 <trap+0x90>
  105012:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  105018:	90                   	nop
  105019:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_COM1:
    uartintr();
  105020:	e8 ab 01 00 00       	call   1051d0 <uartintr>
  105025:	8d 76 00             	lea    0x0(%esi),%esi
    lapiceoi();
  105028:	e8 23 d4 ff ff       	call   102450 <lapiceoi>
  10502d:	8d 76 00             	lea    0x0(%esi),%esi
    break;
  105030:	e9 0b ff ff ff       	jmp    104f40 <trap+0x90>
  105035:	8d 76 00             	lea    0x0(%esi),%esi
  105038:	90                   	nop
  105039:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
  105040:	e8 eb d3 ff ff       	call   102430 <kbdintr>
  105045:	8d 76 00             	lea    0x0(%esi),%esi
    lapiceoi();
  105048:	e8 03 d4 ff ff       	call   102450 <lapiceoi>
  10504d:	8d 76 00             	lea    0x0(%esi),%esi
    break;
  105050:	e9 eb fe ff ff       	jmp    104f40 <trap+0x90>
  105055:	8d 76 00             	lea    0x0(%esi),%esi
    return;
  }

  switch(tf->trapno){
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
  105058:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  10505e:	80 38 00             	cmpb   $0x0,(%eax)
  105061:	0f 85 6e ff ff ff    	jne    104fd5 <trap+0x125>
      acquire(&tickslock);
  105067:	c7 04 24 60 e0 10 00 	movl   $0x10e060,(%esp)
  10506e:	e8 0d ec ff ff       	call   103c80 <acquire>
      ticks++;
  105073:	83 05 a0 e8 10 00 01 	addl   $0x1,0x10e8a0
      wakeup(&ticks);
  10507a:	c7 04 24 a0 e8 10 00 	movl   $0x10e8a0,(%esp)
  105081:	e8 aa e0 ff ff       	call   103130 <wakeup>
      release(&tickslock);
  105086:	c7 04 24 60 e0 10 00 	movl   $0x10e060,(%esp)
  10508d:	e8 9e eb ff ff       	call   103c30 <release>
  105092:	e9 3e ff ff ff       	jmp    104fd5 <trap+0x125>
  105097:	90                   	nop
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
  105098:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
  10509c:	0f 85 c9 fe ff ff    	jne    104f6b <trap+0xbb>
  1050a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    yield();
  1050a8:	e8 73 e2 ff ff       	call   103320 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
  1050ad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1050b3:	85 c0                	test   %eax,%eax
  1050b5:	0f 85 b0 fe ff ff    	jne    104f6b <trap+0xbb>
  1050bb:	e9 be fe ff ff       	jmp    104f7e <trap+0xce>

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
  1050c0:	e8 3b e4 ff ff       	call   103500 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
  1050c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  1050cb:	85 c0                	test   %eax,%eax
  1050cd:	0f 85 8e fe ff ff    	jne    104f61 <trap+0xb1>
  1050d3:	e9 a6 fe ff ff       	jmp    104f7e <trap+0xce>
  1050d8:	0f 20 d2             	mov    %cr2,%edx
    break;
   
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
  1050db:	89 54 24 10          	mov    %edx,0x10(%esp)
  1050df:	8b 53 38             	mov    0x38(%ebx),%edx
  1050e2:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1050e6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
  1050ed:	0f b6 12             	movzbl (%edx),%edx
  1050f0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050f4:	c7 04 24 e4 6c 10 00 	movl   $0x106ce4,(%esp)
  1050fb:	89 54 24 08          	mov    %edx,0x8(%esp)
  1050ff:	e8 2c b4 ff ff       	call   100530 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
  105104:	c7 04 24 5b 6d 10 00 	movl   $0x106d5b,(%esp)
  10510b:	e8 10 b8 ff ff       	call   100920 <panic>

00105110 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
  105110:	55                   	push   %ebp
  105111:	31 c0                	xor    %eax,%eax
  105113:	89 e5                	mov    %esp,%ebp
  105115:	ba a0 e0 10 00       	mov    $0x10e0a0,%edx
  10511a:	83 ec 18             	sub    $0x18,%esp
  10511d:	8d 76 00             	lea    0x0(%esi),%esi
  int i;

  for(i = 0; i < 256; i++)
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  105120:	8b 0c 85 28 73 10 00 	mov    0x107328(,%eax,4),%ecx
  105127:	66 89 0c c5 a0 e0 10 	mov    %cx,0x10e0a0(,%eax,8)
  10512e:	00 
  10512f:	c1 e9 10             	shr    $0x10,%ecx
  105132:	66 c7 44 c2 02 08 00 	movw   $0x8,0x2(%edx,%eax,8)
  105139:	c6 44 c2 04 00       	movb   $0x0,0x4(%edx,%eax,8)
  10513e:	c6 44 c2 05 8e       	movb   $0x8e,0x5(%edx,%eax,8)
  105143:	66 89 4c c2 06       	mov    %cx,0x6(%edx,%eax,8)
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
  105148:	83 c0 01             	add    $0x1,%eax
  10514b:	3d 00 01 00 00       	cmp    $0x100,%eax
  105150:	75 ce                	jne    105120 <tvinit+0x10>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
  105152:	a1 28 74 10 00       	mov    0x107428,%eax
  
  initlock(&tickslock, "time");
  105157:	c7 44 24 04 60 6d 10 	movl   $0x106d60,0x4(%esp)
  10515e:	00 
  10515f:	c7 04 24 60 e0 10 00 	movl   $0x10e060,(%esp)
{
  int i;

  for(i = 0; i < 256; i++)
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
  105166:	66 c7 05 a2 e2 10 00 	movw   $0x8,0x10e2a2
  10516d:	08 00 
  10516f:	66 a3 a0 e2 10 00    	mov    %ax,0x10e2a0
  105175:	c1 e8 10             	shr    $0x10,%eax
  105178:	c6 05 a4 e2 10 00 00 	movb   $0x0,0x10e2a4
  10517f:	c6 05 a5 e2 10 00 ef 	movb   $0xef,0x10e2a5
  105186:	66 a3 a6 e2 10 00    	mov    %ax,0x10e2a6
  
  initlock(&tickslock, "time");
  10518c:	e8 5f e9 ff ff       	call   103af0 <initlock>
}
  105191:	c9                   	leave  
  105192:	c3                   	ret    
  105193:	90                   	nop
  105194:	90                   	nop
  105195:	90                   	nop
  105196:	90                   	nop
  105197:	90                   	nop
  105198:	90                   	nop
  105199:	90                   	nop
  10519a:	90                   	nop
  10519b:	90                   	nop
  10519c:	90                   	nop
  10519d:	90                   	nop
  10519e:	90                   	nop
  10519f:	90                   	nop

001051a0 <uartgetc>:
}

static int
uartgetc(void)
{
  if(!uart)
  1051a0:	a1 cc 78 10 00       	mov    0x1078cc,%eax
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
  1051a5:	55                   	push   %ebp
  1051a6:	89 e5                	mov    %esp,%ebp
  if(!uart)
  1051a8:	85 c0                	test   %eax,%eax
  1051aa:	75 0c                	jne    1051b8 <uartgetc+0x18>
    return -1;
  if(!(inb(COM1+5) & 0x01))
    return -1;
  return inb(COM1+0);
  1051ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  1051b1:	5d                   	pop    %ebp
  1051b2:	c3                   	ret    
  1051b3:	90                   	nop
  1051b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  1051b8:	ba fd 03 00 00       	mov    $0x3fd,%edx
  1051bd:	ec                   	in     (%dx),%al
static int
uartgetc(void)
{
  if(!uart)
    return -1;
  if(!(inb(COM1+5) & 0x01))
  1051be:	a8 01                	test   $0x1,%al
  1051c0:	74 ea                	je     1051ac <uartgetc+0xc>
  1051c2:	b2 f8                	mov    $0xf8,%dl
  1051c4:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
  1051c5:	0f b6 c0             	movzbl %al,%eax
}
  1051c8:	5d                   	pop    %ebp
  1051c9:	c3                   	ret    
  1051ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

001051d0 <uartintr>:

void
uartintr(void)
{
  1051d0:	55                   	push   %ebp
  1051d1:	89 e5                	mov    %esp,%ebp
  1051d3:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
  1051d6:	c7 04 24 a0 51 10 00 	movl   $0x1051a0,(%esp)
  1051dd:	e8 ae b5 ff ff       	call   100790 <consoleintr>
}
  1051e2:	c9                   	leave  
  1051e3:	c3                   	ret    
  1051e4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1051ea:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

001051f0 <uartputc>:
    uartputc(*p);
}

void
uartputc(int c)
{
  1051f0:	55                   	push   %ebp
  1051f1:	89 e5                	mov    %esp,%ebp
  1051f3:	56                   	push   %esi
  1051f4:	be fd 03 00 00       	mov    $0x3fd,%esi
  1051f9:	53                   	push   %ebx
  int i;

  if(!uart)
  1051fa:	31 db                	xor    %ebx,%ebx
    uartputc(*p);
}

void
uartputc(int c)
{
  1051fc:	83 ec 10             	sub    $0x10,%esp
  int i;

  if(!uart)
  1051ff:	8b 15 cc 78 10 00    	mov    0x1078cc,%edx
  105205:	85 d2                	test   %edx,%edx
  105207:	75 1e                	jne    105227 <uartputc+0x37>
  105209:	eb 2c                	jmp    105237 <uartputc+0x47>
  10520b:	90                   	nop
  10520c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
  105210:	83 c3 01             	add    $0x1,%ebx
    microdelay(10);
  105213:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
  10521a:	e8 51 d2 ff ff       	call   102470 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
  10521f:	81 fb 80 00 00 00    	cmp    $0x80,%ebx
  105225:	74 07                	je     10522e <uartputc+0x3e>
  105227:	89 f2                	mov    %esi,%edx
  105229:	ec                   	in     (%dx),%al
  10522a:	a8 20                	test   $0x20,%al
  10522c:	74 e2                	je     105210 <uartputc+0x20>
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
  10522e:	ba f8 03 00 00       	mov    $0x3f8,%edx
  105233:	8b 45 08             	mov    0x8(%ebp),%eax
  105236:	ee                   	out    %al,(%dx)
    microdelay(10);
  outb(COM1+0, c);
}
  105237:	83 c4 10             	add    $0x10,%esp
  10523a:	5b                   	pop    %ebx
  10523b:	5e                   	pop    %esi
  10523c:	5d                   	pop    %ebp
  10523d:	c3                   	ret    
  10523e:	66 90                	xchg   %ax,%ax

00105240 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
  105240:	55                   	push   %ebp
  105241:	31 c9                	xor    %ecx,%ecx
  105243:	89 e5                	mov    %esp,%ebp
  105245:	89 c8                	mov    %ecx,%eax
  105247:	57                   	push   %edi
  105248:	bf fa 03 00 00       	mov    $0x3fa,%edi
  10524d:	56                   	push   %esi
  10524e:	89 fa                	mov    %edi,%edx
  105250:	53                   	push   %ebx
  105251:	83 ec 1c             	sub    $0x1c,%esp
  105254:	ee                   	out    %al,(%dx)
  105255:	bb fb 03 00 00       	mov    $0x3fb,%ebx
  10525a:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
  10525f:	89 da                	mov    %ebx,%edx
  105261:	ee                   	out    %al,(%dx)
  105262:	b8 0c 00 00 00       	mov    $0xc,%eax
  105267:	b2 f8                	mov    $0xf8,%dl
  105269:	ee                   	out    %al,(%dx)
  10526a:	be f9 03 00 00       	mov    $0x3f9,%esi
  10526f:	89 c8                	mov    %ecx,%eax
  105271:	89 f2                	mov    %esi,%edx
  105273:	ee                   	out    %al,(%dx)
  105274:	b8 03 00 00 00       	mov    $0x3,%eax
  105279:	89 da                	mov    %ebx,%edx
  10527b:	ee                   	out    %al,(%dx)
  10527c:	b2 fc                	mov    $0xfc,%dl
  10527e:	89 c8                	mov    %ecx,%eax
  105280:	ee                   	out    %al,(%dx)
  105281:	b8 01 00 00 00       	mov    $0x1,%eax
  105286:	89 f2                	mov    %esi,%edx
  105288:	ee                   	out    %al,(%dx)
static inline uchar
inb(ushort port)
{
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  105289:	b2 fd                	mov    $0xfd,%dl
  10528b:	ec                   	in     (%dx),%al
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
  10528c:	3c ff                	cmp    $0xff,%al
  10528e:	74 55                	je     1052e5 <uartinit+0xa5>
    return;
  uart = 1;
  105290:	c7 05 cc 78 10 00 01 	movl   $0x1,0x1078cc
  105297:	00 00 00 
  10529a:	89 fa                	mov    %edi,%edx
  10529c:	ec                   	in     (%dx),%al
  10529d:	b2 f8                	mov    $0xf8,%dl
  10529f:	ec                   	in     (%dx),%al
  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  1052a0:	bb e8 6d 10 00       	mov    $0x106de8,%ebx

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
  inb(COM1+0);
  picenable(IRQ_COM1);
  1052a5:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  1052ac:	e8 df d8 ff ff       	call   102b90 <picenable>
  ioapicenable(IRQ_COM1, 0);
  1052b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1052b8:	00 
  1052b9:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  1052c0:	e8 7b ce ff ff       	call   102140 <ioapicenable>
  1052c5:	b8 78 00 00 00       	mov    $0x78,%eax
  1052ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
  1052d0:	0f be c0             	movsbl %al,%eax
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
  1052d3:	83 c3 01             	add    $0x1,%ebx
    uartputc(*p);
  1052d6:	89 04 24             	mov    %eax,(%esp)
  1052d9:	e8 12 ff ff ff       	call   1051f0 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
  1052de:	0f b6 03             	movzbl (%ebx),%eax
  1052e1:	84 c0                	test   %al,%al
  1052e3:	75 eb                	jne    1052d0 <uartinit+0x90>
    uartputc(*p);
}
  1052e5:	83 c4 1c             	add    $0x1c,%esp
  1052e8:	5b                   	pop    %ebx
  1052e9:	5e                   	pop    %esi
  1052ea:	5f                   	pop    %edi
  1052eb:	5d                   	pop    %ebp
  1052ec:	c3                   	ret    
  1052ed:	90                   	nop
  1052ee:	90                   	nop
  1052ef:	90                   	nop

001052f0 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
  1052f0:	6a 00                	push   $0x0
  pushl $0
  1052f2:	6a 00                	push   $0x0
  jmp alltraps
  1052f4:	e9 57 fb ff ff       	jmp    104e50 <alltraps>

001052f9 <vector1>:
.globl vector1
vector1:
  pushl $0
  1052f9:	6a 00                	push   $0x0
  pushl $1
  1052fb:	6a 01                	push   $0x1
  jmp alltraps
  1052fd:	e9 4e fb ff ff       	jmp    104e50 <alltraps>

00105302 <vector2>:
.globl vector2
vector2:
  pushl $0
  105302:	6a 00                	push   $0x0
  pushl $2
  105304:	6a 02                	push   $0x2
  jmp alltraps
  105306:	e9 45 fb ff ff       	jmp    104e50 <alltraps>

0010530b <vector3>:
.globl vector3
vector3:
  pushl $0
  10530b:	6a 00                	push   $0x0
  pushl $3
  10530d:	6a 03                	push   $0x3
  jmp alltraps
  10530f:	e9 3c fb ff ff       	jmp    104e50 <alltraps>

00105314 <vector4>:
.globl vector4
vector4:
  pushl $0
  105314:	6a 00                	push   $0x0
  pushl $4
  105316:	6a 04                	push   $0x4
  jmp alltraps
  105318:	e9 33 fb ff ff       	jmp    104e50 <alltraps>

0010531d <vector5>:
.globl vector5
vector5:
  pushl $0
  10531d:	6a 00                	push   $0x0
  pushl $5
  10531f:	6a 05                	push   $0x5
  jmp alltraps
  105321:	e9 2a fb ff ff       	jmp    104e50 <alltraps>

00105326 <vector6>:
.globl vector6
vector6:
  pushl $0
  105326:	6a 00                	push   $0x0
  pushl $6
  105328:	6a 06                	push   $0x6
  jmp alltraps
  10532a:	e9 21 fb ff ff       	jmp    104e50 <alltraps>

0010532f <vector7>:
.globl vector7
vector7:
  pushl $0
  10532f:	6a 00                	push   $0x0
  pushl $7
  105331:	6a 07                	push   $0x7
  jmp alltraps
  105333:	e9 18 fb ff ff       	jmp    104e50 <alltraps>

00105338 <vector8>:
.globl vector8
vector8:
  pushl $8
  105338:	6a 08                	push   $0x8
  jmp alltraps
  10533a:	e9 11 fb ff ff       	jmp    104e50 <alltraps>

0010533f <vector9>:
.globl vector9
vector9:
  pushl $0
  10533f:	6a 00                	push   $0x0
  pushl $9
  105341:	6a 09                	push   $0x9
  jmp alltraps
  105343:	e9 08 fb ff ff       	jmp    104e50 <alltraps>

00105348 <vector10>:
.globl vector10
vector10:
  pushl $10
  105348:	6a 0a                	push   $0xa
  jmp alltraps
  10534a:	e9 01 fb ff ff       	jmp    104e50 <alltraps>

0010534f <vector11>:
.globl vector11
vector11:
  pushl $11
  10534f:	6a 0b                	push   $0xb
  jmp alltraps
  105351:	e9 fa fa ff ff       	jmp    104e50 <alltraps>

00105356 <vector12>:
.globl vector12
vector12:
  pushl $12
  105356:	6a 0c                	push   $0xc
  jmp alltraps
  105358:	e9 f3 fa ff ff       	jmp    104e50 <alltraps>

0010535d <vector13>:
.globl vector13
vector13:
  pushl $13
  10535d:	6a 0d                	push   $0xd
  jmp alltraps
  10535f:	e9 ec fa ff ff       	jmp    104e50 <alltraps>

00105364 <vector14>:
.globl vector14
vector14:
  pushl $14
  105364:	6a 0e                	push   $0xe
  jmp alltraps
  105366:	e9 e5 fa ff ff       	jmp    104e50 <alltraps>

0010536b <vector15>:
.globl vector15
vector15:
  pushl $0
  10536b:	6a 00                	push   $0x0
  pushl $15
  10536d:	6a 0f                	push   $0xf
  jmp alltraps
  10536f:	e9 dc fa ff ff       	jmp    104e50 <alltraps>

00105374 <vector16>:
.globl vector16
vector16:
  pushl $0
  105374:	6a 00                	push   $0x0
  pushl $16
  105376:	6a 10                	push   $0x10
  jmp alltraps
  105378:	e9 d3 fa ff ff       	jmp    104e50 <alltraps>

0010537d <vector17>:
.globl vector17
vector17:
  pushl $17
  10537d:	6a 11                	push   $0x11
  jmp alltraps
  10537f:	e9 cc fa ff ff       	jmp    104e50 <alltraps>

00105384 <vector18>:
.globl vector18
vector18:
  pushl $0
  105384:	6a 00                	push   $0x0
  pushl $18
  105386:	6a 12                	push   $0x12
  jmp alltraps
  105388:	e9 c3 fa ff ff       	jmp    104e50 <alltraps>

0010538d <vector19>:
.globl vector19
vector19:
  pushl $0
  10538d:	6a 00                	push   $0x0
  pushl $19
  10538f:	6a 13                	push   $0x13
  jmp alltraps
  105391:	e9 ba fa ff ff       	jmp    104e50 <alltraps>

00105396 <vector20>:
.globl vector20
vector20:
  pushl $0
  105396:	6a 00                	push   $0x0
  pushl $20
  105398:	6a 14                	push   $0x14
  jmp alltraps
  10539a:	e9 b1 fa ff ff       	jmp    104e50 <alltraps>

0010539f <vector21>:
.globl vector21
vector21:
  pushl $0
  10539f:	6a 00                	push   $0x0
  pushl $21
  1053a1:	6a 15                	push   $0x15
  jmp alltraps
  1053a3:	e9 a8 fa ff ff       	jmp    104e50 <alltraps>

001053a8 <vector22>:
.globl vector22
vector22:
  pushl $0
  1053a8:	6a 00                	push   $0x0
  pushl $22
  1053aa:	6a 16                	push   $0x16
  jmp alltraps
  1053ac:	e9 9f fa ff ff       	jmp    104e50 <alltraps>

001053b1 <vector23>:
.globl vector23
vector23:
  pushl $0
  1053b1:	6a 00                	push   $0x0
  pushl $23
  1053b3:	6a 17                	push   $0x17
  jmp alltraps
  1053b5:	e9 96 fa ff ff       	jmp    104e50 <alltraps>

001053ba <vector24>:
.globl vector24
vector24:
  pushl $0
  1053ba:	6a 00                	push   $0x0
  pushl $24
  1053bc:	6a 18                	push   $0x18
  jmp alltraps
  1053be:	e9 8d fa ff ff       	jmp    104e50 <alltraps>

001053c3 <vector25>:
.globl vector25
vector25:
  pushl $0
  1053c3:	6a 00                	push   $0x0
  pushl $25
  1053c5:	6a 19                	push   $0x19
  jmp alltraps
  1053c7:	e9 84 fa ff ff       	jmp    104e50 <alltraps>

001053cc <vector26>:
.globl vector26
vector26:
  pushl $0
  1053cc:	6a 00                	push   $0x0
  pushl $26
  1053ce:	6a 1a                	push   $0x1a
  jmp alltraps
  1053d0:	e9 7b fa ff ff       	jmp    104e50 <alltraps>

001053d5 <vector27>:
.globl vector27
vector27:
  pushl $0
  1053d5:	6a 00                	push   $0x0
  pushl $27
  1053d7:	6a 1b                	push   $0x1b
  jmp alltraps
  1053d9:	e9 72 fa ff ff       	jmp    104e50 <alltraps>

001053de <vector28>:
.globl vector28
vector28:
  pushl $0
  1053de:	6a 00                	push   $0x0
  pushl $28
  1053e0:	6a 1c                	push   $0x1c
  jmp alltraps
  1053e2:	e9 69 fa ff ff       	jmp    104e50 <alltraps>

001053e7 <vector29>:
.globl vector29
vector29:
  pushl $0
  1053e7:	6a 00                	push   $0x0
  pushl $29
  1053e9:	6a 1d                	push   $0x1d
  jmp alltraps
  1053eb:	e9 60 fa ff ff       	jmp    104e50 <alltraps>

001053f0 <vector30>:
.globl vector30
vector30:
  pushl $0
  1053f0:	6a 00                	push   $0x0
  pushl $30
  1053f2:	6a 1e                	push   $0x1e
  jmp alltraps
  1053f4:	e9 57 fa ff ff       	jmp    104e50 <alltraps>

001053f9 <vector31>:
.globl vector31
vector31:
  pushl $0
  1053f9:	6a 00                	push   $0x0
  pushl $31
  1053fb:	6a 1f                	push   $0x1f
  jmp alltraps
  1053fd:	e9 4e fa ff ff       	jmp    104e50 <alltraps>

00105402 <vector32>:
.globl vector32
vector32:
  pushl $0
  105402:	6a 00                	push   $0x0
  pushl $32
  105404:	6a 20                	push   $0x20
  jmp alltraps
  105406:	e9 45 fa ff ff       	jmp    104e50 <alltraps>

0010540b <vector33>:
.globl vector33
vector33:
  pushl $0
  10540b:	6a 00                	push   $0x0
  pushl $33
  10540d:	6a 21                	push   $0x21
  jmp alltraps
  10540f:	e9 3c fa ff ff       	jmp    104e50 <alltraps>

00105414 <vector34>:
.globl vector34
vector34:
  pushl $0
  105414:	6a 00                	push   $0x0
  pushl $34
  105416:	6a 22                	push   $0x22
  jmp alltraps
  105418:	e9 33 fa ff ff       	jmp    104e50 <alltraps>

0010541d <vector35>:
.globl vector35
vector35:
  pushl $0
  10541d:	6a 00                	push   $0x0
  pushl $35
  10541f:	6a 23                	push   $0x23
  jmp alltraps
  105421:	e9 2a fa ff ff       	jmp    104e50 <alltraps>

00105426 <vector36>:
.globl vector36
vector36:
  pushl $0
  105426:	6a 00                	push   $0x0
  pushl $36
  105428:	6a 24                	push   $0x24
  jmp alltraps
  10542a:	e9 21 fa ff ff       	jmp    104e50 <alltraps>

0010542f <vector37>:
.globl vector37
vector37:
  pushl $0
  10542f:	6a 00                	push   $0x0
  pushl $37
  105431:	6a 25                	push   $0x25
  jmp alltraps
  105433:	e9 18 fa ff ff       	jmp    104e50 <alltraps>

00105438 <vector38>:
.globl vector38
vector38:
  pushl $0
  105438:	6a 00                	push   $0x0
  pushl $38
  10543a:	6a 26                	push   $0x26
  jmp alltraps
  10543c:	e9 0f fa ff ff       	jmp    104e50 <alltraps>

00105441 <vector39>:
.globl vector39
vector39:
  pushl $0
  105441:	6a 00                	push   $0x0
  pushl $39
  105443:	6a 27                	push   $0x27
  jmp alltraps
  105445:	e9 06 fa ff ff       	jmp    104e50 <alltraps>

0010544a <vector40>:
.globl vector40
vector40:
  pushl $0
  10544a:	6a 00                	push   $0x0
  pushl $40
  10544c:	6a 28                	push   $0x28
  jmp alltraps
  10544e:	e9 fd f9 ff ff       	jmp    104e50 <alltraps>

00105453 <vector41>:
.globl vector41
vector41:
  pushl $0
  105453:	6a 00                	push   $0x0
  pushl $41
  105455:	6a 29                	push   $0x29
  jmp alltraps
  105457:	e9 f4 f9 ff ff       	jmp    104e50 <alltraps>

0010545c <vector42>:
.globl vector42
vector42:
  pushl $0
  10545c:	6a 00                	push   $0x0
  pushl $42
  10545e:	6a 2a                	push   $0x2a
  jmp alltraps
  105460:	e9 eb f9 ff ff       	jmp    104e50 <alltraps>

00105465 <vector43>:
.globl vector43
vector43:
  pushl $0
  105465:	6a 00                	push   $0x0
  pushl $43
  105467:	6a 2b                	push   $0x2b
  jmp alltraps
  105469:	e9 e2 f9 ff ff       	jmp    104e50 <alltraps>

0010546e <vector44>:
.globl vector44
vector44:
  pushl $0
  10546e:	6a 00                	push   $0x0
  pushl $44
  105470:	6a 2c                	push   $0x2c
  jmp alltraps
  105472:	e9 d9 f9 ff ff       	jmp    104e50 <alltraps>

00105477 <vector45>:
.globl vector45
vector45:
  pushl $0
  105477:	6a 00                	push   $0x0
  pushl $45
  105479:	6a 2d                	push   $0x2d
  jmp alltraps
  10547b:	e9 d0 f9 ff ff       	jmp    104e50 <alltraps>

00105480 <vector46>:
.globl vector46
vector46:
  pushl $0
  105480:	6a 00                	push   $0x0
  pushl $46
  105482:	6a 2e                	push   $0x2e
  jmp alltraps
  105484:	e9 c7 f9 ff ff       	jmp    104e50 <alltraps>

00105489 <vector47>:
.globl vector47
vector47:
  pushl $0
  105489:	6a 00                	push   $0x0
  pushl $47
  10548b:	6a 2f                	push   $0x2f
  jmp alltraps
  10548d:	e9 be f9 ff ff       	jmp    104e50 <alltraps>

00105492 <vector48>:
.globl vector48
vector48:
  pushl $0
  105492:	6a 00                	push   $0x0
  pushl $48
  105494:	6a 30                	push   $0x30
  jmp alltraps
  105496:	e9 b5 f9 ff ff       	jmp    104e50 <alltraps>

0010549b <vector49>:
.globl vector49
vector49:
  pushl $0
  10549b:	6a 00                	push   $0x0
  pushl $49
  10549d:	6a 31                	push   $0x31
  jmp alltraps
  10549f:	e9 ac f9 ff ff       	jmp    104e50 <alltraps>

001054a4 <vector50>:
.globl vector50
vector50:
  pushl $0
  1054a4:	6a 00                	push   $0x0
  pushl $50
  1054a6:	6a 32                	push   $0x32
  jmp alltraps
  1054a8:	e9 a3 f9 ff ff       	jmp    104e50 <alltraps>

001054ad <vector51>:
.globl vector51
vector51:
  pushl $0
  1054ad:	6a 00                	push   $0x0
  pushl $51
  1054af:	6a 33                	push   $0x33
  jmp alltraps
  1054b1:	e9 9a f9 ff ff       	jmp    104e50 <alltraps>

001054b6 <vector52>:
.globl vector52
vector52:
  pushl $0
  1054b6:	6a 00                	push   $0x0
  pushl $52
  1054b8:	6a 34                	push   $0x34
  jmp alltraps
  1054ba:	e9 91 f9 ff ff       	jmp    104e50 <alltraps>

001054bf <vector53>:
.globl vector53
vector53:
  pushl $0
  1054bf:	6a 00                	push   $0x0
  pushl $53
  1054c1:	6a 35                	push   $0x35
  jmp alltraps
  1054c3:	e9 88 f9 ff ff       	jmp    104e50 <alltraps>

001054c8 <vector54>:
.globl vector54
vector54:
  pushl $0
  1054c8:	6a 00                	push   $0x0
  pushl $54
  1054ca:	6a 36                	push   $0x36
  jmp alltraps
  1054cc:	e9 7f f9 ff ff       	jmp    104e50 <alltraps>

001054d1 <vector55>:
.globl vector55
vector55:
  pushl $0
  1054d1:	6a 00                	push   $0x0
  pushl $55
  1054d3:	6a 37                	push   $0x37
  jmp alltraps
  1054d5:	e9 76 f9 ff ff       	jmp    104e50 <alltraps>

001054da <vector56>:
.globl vector56
vector56:
  pushl $0
  1054da:	6a 00                	push   $0x0
  pushl $56
  1054dc:	6a 38                	push   $0x38
  jmp alltraps
  1054de:	e9 6d f9 ff ff       	jmp    104e50 <alltraps>

001054e3 <vector57>:
.globl vector57
vector57:
  pushl $0
  1054e3:	6a 00                	push   $0x0
  pushl $57
  1054e5:	6a 39                	push   $0x39
  jmp alltraps
  1054e7:	e9 64 f9 ff ff       	jmp    104e50 <alltraps>

001054ec <vector58>:
.globl vector58
vector58:
  pushl $0
  1054ec:	6a 00                	push   $0x0
  pushl $58
  1054ee:	6a 3a                	push   $0x3a
  jmp alltraps
  1054f0:	e9 5b f9 ff ff       	jmp    104e50 <alltraps>

001054f5 <vector59>:
.globl vector59
vector59:
  pushl $0
  1054f5:	6a 00                	push   $0x0
  pushl $59
  1054f7:	6a 3b                	push   $0x3b
  jmp alltraps
  1054f9:	e9 52 f9 ff ff       	jmp    104e50 <alltraps>

001054fe <vector60>:
.globl vector60
vector60:
  pushl $0
  1054fe:	6a 00                	push   $0x0
  pushl $60
  105500:	6a 3c                	push   $0x3c
  jmp alltraps
  105502:	e9 49 f9 ff ff       	jmp    104e50 <alltraps>

00105507 <vector61>:
.globl vector61
vector61:
  pushl $0
  105507:	6a 00                	push   $0x0
  pushl $61
  105509:	6a 3d                	push   $0x3d
  jmp alltraps
  10550b:	e9 40 f9 ff ff       	jmp    104e50 <alltraps>

00105510 <vector62>:
.globl vector62
vector62:
  pushl $0
  105510:	6a 00                	push   $0x0
  pushl $62
  105512:	6a 3e                	push   $0x3e
  jmp alltraps
  105514:	e9 37 f9 ff ff       	jmp    104e50 <alltraps>

00105519 <vector63>:
.globl vector63
vector63:
  pushl $0
  105519:	6a 00                	push   $0x0
  pushl $63
  10551b:	6a 3f                	push   $0x3f
  jmp alltraps
  10551d:	e9 2e f9 ff ff       	jmp    104e50 <alltraps>

00105522 <vector64>:
.globl vector64
vector64:
  pushl $0
  105522:	6a 00                	push   $0x0
  pushl $64
  105524:	6a 40                	push   $0x40
  jmp alltraps
  105526:	e9 25 f9 ff ff       	jmp    104e50 <alltraps>

0010552b <vector65>:
.globl vector65
vector65:
  pushl $0
  10552b:	6a 00                	push   $0x0
  pushl $65
  10552d:	6a 41                	push   $0x41
  jmp alltraps
  10552f:	e9 1c f9 ff ff       	jmp    104e50 <alltraps>

00105534 <vector66>:
.globl vector66
vector66:
  pushl $0
  105534:	6a 00                	push   $0x0
  pushl $66
  105536:	6a 42                	push   $0x42
  jmp alltraps
  105538:	e9 13 f9 ff ff       	jmp    104e50 <alltraps>

0010553d <vector67>:
.globl vector67
vector67:
  pushl $0
  10553d:	6a 00                	push   $0x0
  pushl $67
  10553f:	6a 43                	push   $0x43
  jmp alltraps
  105541:	e9 0a f9 ff ff       	jmp    104e50 <alltraps>

00105546 <vector68>:
.globl vector68
vector68:
  pushl $0
  105546:	6a 00                	push   $0x0
  pushl $68
  105548:	6a 44                	push   $0x44
  jmp alltraps
  10554a:	e9 01 f9 ff ff       	jmp    104e50 <alltraps>

0010554f <vector69>:
.globl vector69
vector69:
  pushl $0
  10554f:	6a 00                	push   $0x0
  pushl $69
  105551:	6a 45                	push   $0x45
  jmp alltraps
  105553:	e9 f8 f8 ff ff       	jmp    104e50 <alltraps>

00105558 <vector70>:
.globl vector70
vector70:
  pushl $0
  105558:	6a 00                	push   $0x0
  pushl $70
  10555a:	6a 46                	push   $0x46
  jmp alltraps
  10555c:	e9 ef f8 ff ff       	jmp    104e50 <alltraps>

00105561 <vector71>:
.globl vector71
vector71:
  pushl $0
  105561:	6a 00                	push   $0x0
  pushl $71
  105563:	6a 47                	push   $0x47
  jmp alltraps
  105565:	e9 e6 f8 ff ff       	jmp    104e50 <alltraps>

0010556a <vector72>:
.globl vector72
vector72:
  pushl $0
  10556a:	6a 00                	push   $0x0
  pushl $72
  10556c:	6a 48                	push   $0x48
  jmp alltraps
  10556e:	e9 dd f8 ff ff       	jmp    104e50 <alltraps>

00105573 <vector73>:
.globl vector73
vector73:
  pushl $0
  105573:	6a 00                	push   $0x0
  pushl $73
  105575:	6a 49                	push   $0x49
  jmp alltraps
  105577:	e9 d4 f8 ff ff       	jmp    104e50 <alltraps>

0010557c <vector74>:
.globl vector74
vector74:
  pushl $0
  10557c:	6a 00                	push   $0x0
  pushl $74
  10557e:	6a 4a                	push   $0x4a
  jmp alltraps
  105580:	e9 cb f8 ff ff       	jmp    104e50 <alltraps>

00105585 <vector75>:
.globl vector75
vector75:
  pushl $0
  105585:	6a 00                	push   $0x0
  pushl $75
  105587:	6a 4b                	push   $0x4b
  jmp alltraps
  105589:	e9 c2 f8 ff ff       	jmp    104e50 <alltraps>

0010558e <vector76>:
.globl vector76
vector76:
  pushl $0
  10558e:	6a 00                	push   $0x0
  pushl $76
  105590:	6a 4c                	push   $0x4c
  jmp alltraps
  105592:	e9 b9 f8 ff ff       	jmp    104e50 <alltraps>

00105597 <vector77>:
.globl vector77
vector77:
  pushl $0
  105597:	6a 00                	push   $0x0
  pushl $77
  105599:	6a 4d                	push   $0x4d
  jmp alltraps
  10559b:	e9 b0 f8 ff ff       	jmp    104e50 <alltraps>

001055a0 <vector78>:
.globl vector78
vector78:
  pushl $0
  1055a0:	6a 00                	push   $0x0
  pushl $78
  1055a2:	6a 4e                	push   $0x4e
  jmp alltraps
  1055a4:	e9 a7 f8 ff ff       	jmp    104e50 <alltraps>

001055a9 <vector79>:
.globl vector79
vector79:
  pushl $0
  1055a9:	6a 00                	push   $0x0
  pushl $79
  1055ab:	6a 4f                	push   $0x4f
  jmp alltraps
  1055ad:	e9 9e f8 ff ff       	jmp    104e50 <alltraps>

001055b2 <vector80>:
.globl vector80
vector80:
  pushl $0
  1055b2:	6a 00                	push   $0x0
  pushl $80
  1055b4:	6a 50                	push   $0x50
  jmp alltraps
  1055b6:	e9 95 f8 ff ff       	jmp    104e50 <alltraps>

001055bb <vector81>:
.globl vector81
vector81:
  pushl $0
  1055bb:	6a 00                	push   $0x0
  pushl $81
  1055bd:	6a 51                	push   $0x51
  jmp alltraps
  1055bf:	e9 8c f8 ff ff       	jmp    104e50 <alltraps>

001055c4 <vector82>:
.globl vector82
vector82:
  pushl $0
  1055c4:	6a 00                	push   $0x0
  pushl $82
  1055c6:	6a 52                	push   $0x52
  jmp alltraps
  1055c8:	e9 83 f8 ff ff       	jmp    104e50 <alltraps>

001055cd <vector83>:
.globl vector83
vector83:
  pushl $0
  1055cd:	6a 00                	push   $0x0
  pushl $83
  1055cf:	6a 53                	push   $0x53
  jmp alltraps
  1055d1:	e9 7a f8 ff ff       	jmp    104e50 <alltraps>

001055d6 <vector84>:
.globl vector84
vector84:
  pushl $0
  1055d6:	6a 00                	push   $0x0
  pushl $84
  1055d8:	6a 54                	push   $0x54
  jmp alltraps
  1055da:	e9 71 f8 ff ff       	jmp    104e50 <alltraps>

001055df <vector85>:
.globl vector85
vector85:
  pushl $0
  1055df:	6a 00                	push   $0x0
  pushl $85
  1055e1:	6a 55                	push   $0x55
  jmp alltraps
  1055e3:	e9 68 f8 ff ff       	jmp    104e50 <alltraps>

001055e8 <vector86>:
.globl vector86
vector86:
  pushl $0
  1055e8:	6a 00                	push   $0x0
  pushl $86
  1055ea:	6a 56                	push   $0x56
  jmp alltraps
  1055ec:	e9 5f f8 ff ff       	jmp    104e50 <alltraps>

001055f1 <vector87>:
.globl vector87
vector87:
  pushl $0
  1055f1:	6a 00                	push   $0x0
  pushl $87
  1055f3:	6a 57                	push   $0x57
  jmp alltraps
  1055f5:	e9 56 f8 ff ff       	jmp    104e50 <alltraps>

001055fa <vector88>:
.globl vector88
vector88:
  pushl $0
  1055fa:	6a 00                	push   $0x0
  pushl $88
  1055fc:	6a 58                	push   $0x58
  jmp alltraps
  1055fe:	e9 4d f8 ff ff       	jmp    104e50 <alltraps>

00105603 <vector89>:
.globl vector89
vector89:
  pushl $0
  105603:	6a 00                	push   $0x0
  pushl $89
  105605:	6a 59                	push   $0x59
  jmp alltraps
  105607:	e9 44 f8 ff ff       	jmp    104e50 <alltraps>

0010560c <vector90>:
.globl vector90
vector90:
  pushl $0
  10560c:	6a 00                	push   $0x0
  pushl $90
  10560e:	6a 5a                	push   $0x5a
  jmp alltraps
  105610:	e9 3b f8 ff ff       	jmp    104e50 <alltraps>

00105615 <vector91>:
.globl vector91
vector91:
  pushl $0
  105615:	6a 00                	push   $0x0
  pushl $91
  105617:	6a 5b                	push   $0x5b
  jmp alltraps
  105619:	e9 32 f8 ff ff       	jmp    104e50 <alltraps>

0010561e <vector92>:
.globl vector92
vector92:
  pushl $0
  10561e:	6a 00                	push   $0x0
  pushl $92
  105620:	6a 5c                	push   $0x5c
  jmp alltraps
  105622:	e9 29 f8 ff ff       	jmp    104e50 <alltraps>

00105627 <vector93>:
.globl vector93
vector93:
  pushl $0
  105627:	6a 00                	push   $0x0
  pushl $93
  105629:	6a 5d                	push   $0x5d
  jmp alltraps
  10562b:	e9 20 f8 ff ff       	jmp    104e50 <alltraps>

00105630 <vector94>:
.globl vector94
vector94:
  pushl $0
  105630:	6a 00                	push   $0x0
  pushl $94
  105632:	6a 5e                	push   $0x5e
  jmp alltraps
  105634:	e9 17 f8 ff ff       	jmp    104e50 <alltraps>

00105639 <vector95>:
.globl vector95
vector95:
  pushl $0
  105639:	6a 00                	push   $0x0
  pushl $95
  10563b:	6a 5f                	push   $0x5f
  jmp alltraps
  10563d:	e9 0e f8 ff ff       	jmp    104e50 <alltraps>

00105642 <vector96>:
.globl vector96
vector96:
  pushl $0
  105642:	6a 00                	push   $0x0
  pushl $96
  105644:	6a 60                	push   $0x60
  jmp alltraps
  105646:	e9 05 f8 ff ff       	jmp    104e50 <alltraps>

0010564b <vector97>:
.globl vector97
vector97:
  pushl $0
  10564b:	6a 00                	push   $0x0
  pushl $97
  10564d:	6a 61                	push   $0x61
  jmp alltraps
  10564f:	e9 fc f7 ff ff       	jmp    104e50 <alltraps>

00105654 <vector98>:
.globl vector98
vector98:
  pushl $0
  105654:	6a 00                	push   $0x0
  pushl $98
  105656:	6a 62                	push   $0x62
  jmp alltraps
  105658:	e9 f3 f7 ff ff       	jmp    104e50 <alltraps>

0010565d <vector99>:
.globl vector99
vector99:
  pushl $0
  10565d:	6a 00                	push   $0x0
  pushl $99
  10565f:	6a 63                	push   $0x63
  jmp alltraps
  105661:	e9 ea f7 ff ff       	jmp    104e50 <alltraps>

00105666 <vector100>:
.globl vector100
vector100:
  pushl $0
  105666:	6a 00                	push   $0x0
  pushl $100
  105668:	6a 64                	push   $0x64
  jmp alltraps
  10566a:	e9 e1 f7 ff ff       	jmp    104e50 <alltraps>

0010566f <vector101>:
.globl vector101
vector101:
  pushl $0
  10566f:	6a 00                	push   $0x0
  pushl $101
  105671:	6a 65                	push   $0x65
  jmp alltraps
  105673:	e9 d8 f7 ff ff       	jmp    104e50 <alltraps>

00105678 <vector102>:
.globl vector102
vector102:
  pushl $0
  105678:	6a 00                	push   $0x0
  pushl $102
  10567a:	6a 66                	push   $0x66
  jmp alltraps
  10567c:	e9 cf f7 ff ff       	jmp    104e50 <alltraps>

00105681 <vector103>:
.globl vector103
vector103:
  pushl $0
  105681:	6a 00                	push   $0x0
  pushl $103
  105683:	6a 67                	push   $0x67
  jmp alltraps
  105685:	e9 c6 f7 ff ff       	jmp    104e50 <alltraps>

0010568a <vector104>:
.globl vector104
vector104:
  pushl $0
  10568a:	6a 00                	push   $0x0
  pushl $104
  10568c:	6a 68                	push   $0x68
  jmp alltraps
  10568e:	e9 bd f7 ff ff       	jmp    104e50 <alltraps>

00105693 <vector105>:
.globl vector105
vector105:
  pushl $0
  105693:	6a 00                	push   $0x0
  pushl $105
  105695:	6a 69                	push   $0x69
  jmp alltraps
  105697:	e9 b4 f7 ff ff       	jmp    104e50 <alltraps>

0010569c <vector106>:
.globl vector106
vector106:
  pushl $0
  10569c:	6a 00                	push   $0x0
  pushl $106
  10569e:	6a 6a                	push   $0x6a
  jmp alltraps
  1056a0:	e9 ab f7 ff ff       	jmp    104e50 <alltraps>

001056a5 <vector107>:
.globl vector107
vector107:
  pushl $0
  1056a5:	6a 00                	push   $0x0
  pushl $107
  1056a7:	6a 6b                	push   $0x6b
  jmp alltraps
  1056a9:	e9 a2 f7 ff ff       	jmp    104e50 <alltraps>

001056ae <vector108>:
.globl vector108
vector108:
  pushl $0
  1056ae:	6a 00                	push   $0x0
  pushl $108
  1056b0:	6a 6c                	push   $0x6c
  jmp alltraps
  1056b2:	e9 99 f7 ff ff       	jmp    104e50 <alltraps>

001056b7 <vector109>:
.globl vector109
vector109:
  pushl $0
  1056b7:	6a 00                	push   $0x0
  pushl $109
  1056b9:	6a 6d                	push   $0x6d
  jmp alltraps
  1056bb:	e9 90 f7 ff ff       	jmp    104e50 <alltraps>

001056c0 <vector110>:
.globl vector110
vector110:
  pushl $0
  1056c0:	6a 00                	push   $0x0
  pushl $110
  1056c2:	6a 6e                	push   $0x6e
  jmp alltraps
  1056c4:	e9 87 f7 ff ff       	jmp    104e50 <alltraps>

001056c9 <vector111>:
.globl vector111
vector111:
  pushl $0
  1056c9:	6a 00                	push   $0x0
  pushl $111
  1056cb:	6a 6f                	push   $0x6f
  jmp alltraps
  1056cd:	e9 7e f7 ff ff       	jmp    104e50 <alltraps>

001056d2 <vector112>:
.globl vector112
vector112:
  pushl $0
  1056d2:	6a 00                	push   $0x0
  pushl $112
  1056d4:	6a 70                	push   $0x70
  jmp alltraps
  1056d6:	e9 75 f7 ff ff       	jmp    104e50 <alltraps>

001056db <vector113>:
.globl vector113
vector113:
  pushl $0
  1056db:	6a 00                	push   $0x0
  pushl $113
  1056dd:	6a 71                	push   $0x71
  jmp alltraps
  1056df:	e9 6c f7 ff ff       	jmp    104e50 <alltraps>

001056e4 <vector114>:
.globl vector114
vector114:
  pushl $0
  1056e4:	6a 00                	push   $0x0
  pushl $114
  1056e6:	6a 72                	push   $0x72
  jmp alltraps
  1056e8:	e9 63 f7 ff ff       	jmp    104e50 <alltraps>

001056ed <vector115>:
.globl vector115
vector115:
  pushl $0
  1056ed:	6a 00                	push   $0x0
  pushl $115
  1056ef:	6a 73                	push   $0x73
  jmp alltraps
  1056f1:	e9 5a f7 ff ff       	jmp    104e50 <alltraps>

001056f6 <vector116>:
.globl vector116
vector116:
  pushl $0
  1056f6:	6a 00                	push   $0x0
  pushl $116
  1056f8:	6a 74                	push   $0x74
  jmp alltraps
  1056fa:	e9 51 f7 ff ff       	jmp    104e50 <alltraps>

001056ff <vector117>:
.globl vector117
vector117:
  pushl $0
  1056ff:	6a 00                	push   $0x0
  pushl $117
  105701:	6a 75                	push   $0x75
  jmp alltraps
  105703:	e9 48 f7 ff ff       	jmp    104e50 <alltraps>

00105708 <vector118>:
.globl vector118
vector118:
  pushl $0
  105708:	6a 00                	push   $0x0
  pushl $118
  10570a:	6a 76                	push   $0x76
  jmp alltraps
  10570c:	e9 3f f7 ff ff       	jmp    104e50 <alltraps>

00105711 <vector119>:
.globl vector119
vector119:
  pushl $0
  105711:	6a 00                	push   $0x0
  pushl $119
  105713:	6a 77                	push   $0x77
  jmp alltraps
  105715:	e9 36 f7 ff ff       	jmp    104e50 <alltraps>

0010571a <vector120>:
.globl vector120
vector120:
  pushl $0
  10571a:	6a 00                	push   $0x0
  pushl $120
  10571c:	6a 78                	push   $0x78
  jmp alltraps
  10571e:	e9 2d f7 ff ff       	jmp    104e50 <alltraps>

00105723 <vector121>:
.globl vector121
vector121:
  pushl $0
  105723:	6a 00                	push   $0x0
  pushl $121
  105725:	6a 79                	push   $0x79
  jmp alltraps
  105727:	e9 24 f7 ff ff       	jmp    104e50 <alltraps>

0010572c <vector122>:
.globl vector122
vector122:
  pushl $0
  10572c:	6a 00                	push   $0x0
  pushl $122
  10572e:	6a 7a                	push   $0x7a
  jmp alltraps
  105730:	e9 1b f7 ff ff       	jmp    104e50 <alltraps>

00105735 <vector123>:
.globl vector123
vector123:
  pushl $0
  105735:	6a 00                	push   $0x0
  pushl $123
  105737:	6a 7b                	push   $0x7b
  jmp alltraps
  105739:	e9 12 f7 ff ff       	jmp    104e50 <alltraps>

0010573e <vector124>:
.globl vector124
vector124:
  pushl $0
  10573e:	6a 00                	push   $0x0
  pushl $124
  105740:	6a 7c                	push   $0x7c
  jmp alltraps
  105742:	e9 09 f7 ff ff       	jmp    104e50 <alltraps>

00105747 <vector125>:
.globl vector125
vector125:
  pushl $0
  105747:	6a 00                	push   $0x0
  pushl $125
  105749:	6a 7d                	push   $0x7d
  jmp alltraps
  10574b:	e9 00 f7 ff ff       	jmp    104e50 <alltraps>

00105750 <vector126>:
.globl vector126
vector126:
  pushl $0
  105750:	6a 00                	push   $0x0
  pushl $126
  105752:	6a 7e                	push   $0x7e
  jmp alltraps
  105754:	e9 f7 f6 ff ff       	jmp    104e50 <alltraps>

00105759 <vector127>:
.globl vector127
vector127:
  pushl $0
  105759:	6a 00                	push   $0x0
  pushl $127
  10575b:	6a 7f                	push   $0x7f
  jmp alltraps
  10575d:	e9 ee f6 ff ff       	jmp    104e50 <alltraps>

00105762 <vector128>:
.globl vector128
vector128:
  pushl $0
  105762:	6a 00                	push   $0x0
  pushl $128
  105764:	68 80 00 00 00       	push   $0x80
  jmp alltraps
  105769:	e9 e2 f6 ff ff       	jmp    104e50 <alltraps>

0010576e <vector129>:
.globl vector129
vector129:
  pushl $0
  10576e:	6a 00                	push   $0x0
  pushl $129
  105770:	68 81 00 00 00       	push   $0x81
  jmp alltraps
  105775:	e9 d6 f6 ff ff       	jmp    104e50 <alltraps>

0010577a <vector130>:
.globl vector130
vector130:
  pushl $0
  10577a:	6a 00                	push   $0x0
  pushl $130
  10577c:	68 82 00 00 00       	push   $0x82
  jmp alltraps
  105781:	e9 ca f6 ff ff       	jmp    104e50 <alltraps>

00105786 <vector131>:
.globl vector131
vector131:
  pushl $0
  105786:	6a 00                	push   $0x0
  pushl $131
  105788:	68 83 00 00 00       	push   $0x83
  jmp alltraps
  10578d:	e9 be f6 ff ff       	jmp    104e50 <alltraps>

00105792 <vector132>:
.globl vector132
vector132:
  pushl $0
  105792:	6a 00                	push   $0x0
  pushl $132
  105794:	68 84 00 00 00       	push   $0x84
  jmp alltraps
  105799:	e9 b2 f6 ff ff       	jmp    104e50 <alltraps>

0010579e <vector133>:
.globl vector133
vector133:
  pushl $0
  10579e:	6a 00                	push   $0x0
  pushl $133
  1057a0:	68 85 00 00 00       	push   $0x85
  jmp alltraps
  1057a5:	e9 a6 f6 ff ff       	jmp    104e50 <alltraps>

001057aa <vector134>:
.globl vector134
vector134:
  pushl $0
  1057aa:	6a 00                	push   $0x0
  pushl $134
  1057ac:	68 86 00 00 00       	push   $0x86
  jmp alltraps
  1057b1:	e9 9a f6 ff ff       	jmp    104e50 <alltraps>

001057b6 <vector135>:
.globl vector135
vector135:
  pushl $0
  1057b6:	6a 00                	push   $0x0
  pushl $135
  1057b8:	68 87 00 00 00       	push   $0x87
  jmp alltraps
  1057bd:	e9 8e f6 ff ff       	jmp    104e50 <alltraps>

001057c2 <vector136>:
.globl vector136
vector136:
  pushl $0
  1057c2:	6a 00                	push   $0x0
  pushl $136
  1057c4:	68 88 00 00 00       	push   $0x88
  jmp alltraps
  1057c9:	e9 82 f6 ff ff       	jmp    104e50 <alltraps>

001057ce <vector137>:
.globl vector137
vector137:
  pushl $0
  1057ce:	6a 00                	push   $0x0
  pushl $137
  1057d0:	68 89 00 00 00       	push   $0x89
  jmp alltraps
  1057d5:	e9 76 f6 ff ff       	jmp    104e50 <alltraps>

001057da <vector138>:
.globl vector138
vector138:
  pushl $0
  1057da:	6a 00                	push   $0x0
  pushl $138
  1057dc:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
  1057e1:	e9 6a f6 ff ff       	jmp    104e50 <alltraps>

001057e6 <vector139>:
.globl vector139
vector139:
  pushl $0
  1057e6:	6a 00                	push   $0x0
  pushl $139
  1057e8:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
  1057ed:	e9 5e f6 ff ff       	jmp    104e50 <alltraps>

001057f2 <vector140>:
.globl vector140
vector140:
  pushl $0
  1057f2:	6a 00                	push   $0x0
  pushl $140
  1057f4:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
  1057f9:	e9 52 f6 ff ff       	jmp    104e50 <alltraps>

001057fe <vector141>:
.globl vector141
vector141:
  pushl $0
  1057fe:	6a 00                	push   $0x0
  pushl $141
  105800:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
  105805:	e9 46 f6 ff ff       	jmp    104e50 <alltraps>

0010580a <vector142>:
.globl vector142
vector142:
  pushl $0
  10580a:	6a 00                	push   $0x0
  pushl $142
  10580c:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
  105811:	e9 3a f6 ff ff       	jmp    104e50 <alltraps>

00105816 <vector143>:
.globl vector143
vector143:
  pushl $0
  105816:	6a 00                	push   $0x0
  pushl $143
  105818:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
  10581d:	e9 2e f6 ff ff       	jmp    104e50 <alltraps>

00105822 <vector144>:
.globl vector144
vector144:
  pushl $0
  105822:	6a 00                	push   $0x0
  pushl $144
  105824:	68 90 00 00 00       	push   $0x90
  jmp alltraps
  105829:	e9 22 f6 ff ff       	jmp    104e50 <alltraps>

0010582e <vector145>:
.globl vector145
vector145:
  pushl $0
  10582e:	6a 00                	push   $0x0
  pushl $145
  105830:	68 91 00 00 00       	push   $0x91
  jmp alltraps
  105835:	e9 16 f6 ff ff       	jmp    104e50 <alltraps>

0010583a <vector146>:
.globl vector146
vector146:
  pushl $0
  10583a:	6a 00                	push   $0x0
  pushl $146
  10583c:	68 92 00 00 00       	push   $0x92
  jmp alltraps
  105841:	e9 0a f6 ff ff       	jmp    104e50 <alltraps>

00105846 <vector147>:
.globl vector147
vector147:
  pushl $0
  105846:	6a 00                	push   $0x0
  pushl $147
  105848:	68 93 00 00 00       	push   $0x93
  jmp alltraps
  10584d:	e9 fe f5 ff ff       	jmp    104e50 <alltraps>

00105852 <vector148>:
.globl vector148
vector148:
  pushl $0
  105852:	6a 00                	push   $0x0
  pushl $148
  105854:	68 94 00 00 00       	push   $0x94
  jmp alltraps
  105859:	e9 f2 f5 ff ff       	jmp    104e50 <alltraps>

0010585e <vector149>:
.globl vector149
vector149:
  pushl $0
  10585e:	6a 00                	push   $0x0
  pushl $149
  105860:	68 95 00 00 00       	push   $0x95
  jmp alltraps
  105865:	e9 e6 f5 ff ff       	jmp    104e50 <alltraps>

0010586a <vector150>:
.globl vector150
vector150:
  pushl $0
  10586a:	6a 00                	push   $0x0
  pushl $150
  10586c:	68 96 00 00 00       	push   $0x96
  jmp alltraps
  105871:	e9 da f5 ff ff       	jmp    104e50 <alltraps>

00105876 <vector151>:
.globl vector151
vector151:
  pushl $0
  105876:	6a 00                	push   $0x0
  pushl $151
  105878:	68 97 00 00 00       	push   $0x97
  jmp alltraps
  10587d:	e9 ce f5 ff ff       	jmp    104e50 <alltraps>

00105882 <vector152>:
.globl vector152
vector152:
  pushl $0
  105882:	6a 00                	push   $0x0
  pushl $152
  105884:	68 98 00 00 00       	push   $0x98
  jmp alltraps
  105889:	e9 c2 f5 ff ff       	jmp    104e50 <alltraps>

0010588e <vector153>:
.globl vector153
vector153:
  pushl $0
  10588e:	6a 00                	push   $0x0
  pushl $153
  105890:	68 99 00 00 00       	push   $0x99
  jmp alltraps
  105895:	e9 b6 f5 ff ff       	jmp    104e50 <alltraps>

0010589a <vector154>:
.globl vector154
vector154:
  pushl $0
  10589a:	6a 00                	push   $0x0
  pushl $154
  10589c:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
  1058a1:	e9 aa f5 ff ff       	jmp    104e50 <alltraps>

001058a6 <vector155>:
.globl vector155
vector155:
  pushl $0
  1058a6:	6a 00                	push   $0x0
  pushl $155
  1058a8:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
  1058ad:	e9 9e f5 ff ff       	jmp    104e50 <alltraps>

001058b2 <vector156>:
.globl vector156
vector156:
  pushl $0
  1058b2:	6a 00                	push   $0x0
  pushl $156
  1058b4:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
  1058b9:	e9 92 f5 ff ff       	jmp    104e50 <alltraps>

001058be <vector157>:
.globl vector157
vector157:
  pushl $0
  1058be:	6a 00                	push   $0x0
  pushl $157
  1058c0:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
  1058c5:	e9 86 f5 ff ff       	jmp    104e50 <alltraps>

001058ca <vector158>:
.globl vector158
vector158:
  pushl $0
  1058ca:	6a 00                	push   $0x0
  pushl $158
  1058cc:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
  1058d1:	e9 7a f5 ff ff       	jmp    104e50 <alltraps>

001058d6 <vector159>:
.globl vector159
vector159:
  pushl $0
  1058d6:	6a 00                	push   $0x0
  pushl $159
  1058d8:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
  1058dd:	e9 6e f5 ff ff       	jmp    104e50 <alltraps>

001058e2 <vector160>:
.globl vector160
vector160:
  pushl $0
  1058e2:	6a 00                	push   $0x0
  pushl $160
  1058e4:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
  1058e9:	e9 62 f5 ff ff       	jmp    104e50 <alltraps>

001058ee <vector161>:
.globl vector161
vector161:
  pushl $0
  1058ee:	6a 00                	push   $0x0
  pushl $161
  1058f0:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
  1058f5:	e9 56 f5 ff ff       	jmp    104e50 <alltraps>

001058fa <vector162>:
.globl vector162
vector162:
  pushl $0
  1058fa:	6a 00                	push   $0x0
  pushl $162
  1058fc:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
  105901:	e9 4a f5 ff ff       	jmp    104e50 <alltraps>

00105906 <vector163>:
.globl vector163
vector163:
  pushl $0
  105906:	6a 00                	push   $0x0
  pushl $163
  105908:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
  10590d:	e9 3e f5 ff ff       	jmp    104e50 <alltraps>

00105912 <vector164>:
.globl vector164
vector164:
  pushl $0
  105912:	6a 00                	push   $0x0
  pushl $164
  105914:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
  105919:	e9 32 f5 ff ff       	jmp    104e50 <alltraps>

0010591e <vector165>:
.globl vector165
vector165:
  pushl $0
  10591e:	6a 00                	push   $0x0
  pushl $165
  105920:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
  105925:	e9 26 f5 ff ff       	jmp    104e50 <alltraps>

0010592a <vector166>:
.globl vector166
vector166:
  pushl $0
  10592a:	6a 00                	push   $0x0
  pushl $166
  10592c:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
  105931:	e9 1a f5 ff ff       	jmp    104e50 <alltraps>

00105936 <vector167>:
.globl vector167
vector167:
  pushl $0
  105936:	6a 00                	push   $0x0
  pushl $167
  105938:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
  10593d:	e9 0e f5 ff ff       	jmp    104e50 <alltraps>

00105942 <vector168>:
.globl vector168
vector168:
  pushl $0
  105942:	6a 00                	push   $0x0
  pushl $168
  105944:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
  105949:	e9 02 f5 ff ff       	jmp    104e50 <alltraps>

0010594e <vector169>:
.globl vector169
vector169:
  pushl $0
  10594e:	6a 00                	push   $0x0
  pushl $169
  105950:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
  105955:	e9 f6 f4 ff ff       	jmp    104e50 <alltraps>

0010595a <vector170>:
.globl vector170
vector170:
  pushl $0
  10595a:	6a 00                	push   $0x0
  pushl $170
  10595c:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
  105961:	e9 ea f4 ff ff       	jmp    104e50 <alltraps>

00105966 <vector171>:
.globl vector171
vector171:
  pushl $0
  105966:	6a 00                	push   $0x0
  pushl $171
  105968:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
  10596d:	e9 de f4 ff ff       	jmp    104e50 <alltraps>

00105972 <vector172>:
.globl vector172
vector172:
  pushl $0
  105972:	6a 00                	push   $0x0
  pushl $172
  105974:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
  105979:	e9 d2 f4 ff ff       	jmp    104e50 <alltraps>

0010597e <vector173>:
.globl vector173
vector173:
  pushl $0
  10597e:	6a 00                	push   $0x0
  pushl $173
  105980:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
  105985:	e9 c6 f4 ff ff       	jmp    104e50 <alltraps>

0010598a <vector174>:
.globl vector174
vector174:
  pushl $0
  10598a:	6a 00                	push   $0x0
  pushl $174
  10598c:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
  105991:	e9 ba f4 ff ff       	jmp    104e50 <alltraps>

00105996 <vector175>:
.globl vector175
vector175:
  pushl $0
  105996:	6a 00                	push   $0x0
  pushl $175
  105998:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
  10599d:	e9 ae f4 ff ff       	jmp    104e50 <alltraps>

001059a2 <vector176>:
.globl vector176
vector176:
  pushl $0
  1059a2:	6a 00                	push   $0x0
  pushl $176
  1059a4:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
  1059a9:	e9 a2 f4 ff ff       	jmp    104e50 <alltraps>

001059ae <vector177>:
.globl vector177
vector177:
  pushl $0
  1059ae:	6a 00                	push   $0x0
  pushl $177
  1059b0:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
  1059b5:	e9 96 f4 ff ff       	jmp    104e50 <alltraps>

001059ba <vector178>:
.globl vector178
vector178:
  pushl $0
  1059ba:	6a 00                	push   $0x0
  pushl $178
  1059bc:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
  1059c1:	e9 8a f4 ff ff       	jmp    104e50 <alltraps>

001059c6 <vector179>:
.globl vector179
vector179:
  pushl $0
  1059c6:	6a 00                	push   $0x0
  pushl $179
  1059c8:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
  1059cd:	e9 7e f4 ff ff       	jmp    104e50 <alltraps>

001059d2 <vector180>:
.globl vector180
vector180:
  pushl $0
  1059d2:	6a 00                	push   $0x0
  pushl $180
  1059d4:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
  1059d9:	e9 72 f4 ff ff       	jmp    104e50 <alltraps>

001059de <vector181>:
.globl vector181
vector181:
  pushl $0
  1059de:	6a 00                	push   $0x0
  pushl $181
  1059e0:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
  1059e5:	e9 66 f4 ff ff       	jmp    104e50 <alltraps>

001059ea <vector182>:
.globl vector182
vector182:
  pushl $0
  1059ea:	6a 00                	push   $0x0
  pushl $182
  1059ec:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
  1059f1:	e9 5a f4 ff ff       	jmp    104e50 <alltraps>

001059f6 <vector183>:
.globl vector183
vector183:
  pushl $0
  1059f6:	6a 00                	push   $0x0
  pushl $183
  1059f8:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
  1059fd:	e9 4e f4 ff ff       	jmp    104e50 <alltraps>

00105a02 <vector184>:
.globl vector184
vector184:
  pushl $0
  105a02:	6a 00                	push   $0x0
  pushl $184
  105a04:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
  105a09:	e9 42 f4 ff ff       	jmp    104e50 <alltraps>

00105a0e <vector185>:
.globl vector185
vector185:
  pushl $0
  105a0e:	6a 00                	push   $0x0
  pushl $185
  105a10:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
  105a15:	e9 36 f4 ff ff       	jmp    104e50 <alltraps>

00105a1a <vector186>:
.globl vector186
vector186:
  pushl $0
  105a1a:	6a 00                	push   $0x0
  pushl $186
  105a1c:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
  105a21:	e9 2a f4 ff ff       	jmp    104e50 <alltraps>

00105a26 <vector187>:
.globl vector187
vector187:
  pushl $0
  105a26:	6a 00                	push   $0x0
  pushl $187
  105a28:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
  105a2d:	e9 1e f4 ff ff       	jmp    104e50 <alltraps>

00105a32 <vector188>:
.globl vector188
vector188:
  pushl $0
  105a32:	6a 00                	push   $0x0
  pushl $188
  105a34:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
  105a39:	e9 12 f4 ff ff       	jmp    104e50 <alltraps>

00105a3e <vector189>:
.globl vector189
vector189:
  pushl $0
  105a3e:	6a 00                	push   $0x0
  pushl $189
  105a40:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
  105a45:	e9 06 f4 ff ff       	jmp    104e50 <alltraps>

00105a4a <vector190>:
.globl vector190
vector190:
  pushl $0
  105a4a:	6a 00                	push   $0x0
  pushl $190
  105a4c:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
  105a51:	e9 fa f3 ff ff       	jmp    104e50 <alltraps>

00105a56 <vector191>:
.globl vector191
vector191:
  pushl $0
  105a56:	6a 00                	push   $0x0
  pushl $191
  105a58:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
  105a5d:	e9 ee f3 ff ff       	jmp    104e50 <alltraps>

00105a62 <vector192>:
.globl vector192
vector192:
  pushl $0
  105a62:	6a 00                	push   $0x0
  pushl $192
  105a64:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
  105a69:	e9 e2 f3 ff ff       	jmp    104e50 <alltraps>

00105a6e <vector193>:
.globl vector193
vector193:
  pushl $0
  105a6e:	6a 00                	push   $0x0
  pushl $193
  105a70:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
  105a75:	e9 d6 f3 ff ff       	jmp    104e50 <alltraps>

00105a7a <vector194>:
.globl vector194
vector194:
  pushl $0
  105a7a:	6a 00                	push   $0x0
  pushl $194
  105a7c:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
  105a81:	e9 ca f3 ff ff       	jmp    104e50 <alltraps>

00105a86 <vector195>:
.globl vector195
vector195:
  pushl $0
  105a86:	6a 00                	push   $0x0
  pushl $195
  105a88:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
  105a8d:	e9 be f3 ff ff       	jmp    104e50 <alltraps>

00105a92 <vector196>:
.globl vector196
vector196:
  pushl $0
  105a92:	6a 00                	push   $0x0
  pushl $196
  105a94:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
  105a99:	e9 b2 f3 ff ff       	jmp    104e50 <alltraps>

00105a9e <vector197>:
.globl vector197
vector197:
  pushl $0
  105a9e:	6a 00                	push   $0x0
  pushl $197
  105aa0:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
  105aa5:	e9 a6 f3 ff ff       	jmp    104e50 <alltraps>

00105aaa <vector198>:
.globl vector198
vector198:
  pushl $0
  105aaa:	6a 00                	push   $0x0
  pushl $198
  105aac:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
  105ab1:	e9 9a f3 ff ff       	jmp    104e50 <alltraps>

00105ab6 <vector199>:
.globl vector199
vector199:
  pushl $0
  105ab6:	6a 00                	push   $0x0
  pushl $199
  105ab8:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
  105abd:	e9 8e f3 ff ff       	jmp    104e50 <alltraps>

00105ac2 <vector200>:
.globl vector200
vector200:
  pushl $0
  105ac2:	6a 00                	push   $0x0
  pushl $200
  105ac4:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
  105ac9:	e9 82 f3 ff ff       	jmp    104e50 <alltraps>

00105ace <vector201>:
.globl vector201
vector201:
  pushl $0
  105ace:	6a 00                	push   $0x0
  pushl $201
  105ad0:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
  105ad5:	e9 76 f3 ff ff       	jmp    104e50 <alltraps>

00105ada <vector202>:
.globl vector202
vector202:
  pushl $0
  105ada:	6a 00                	push   $0x0
  pushl $202
  105adc:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
  105ae1:	e9 6a f3 ff ff       	jmp    104e50 <alltraps>

00105ae6 <vector203>:
.globl vector203
vector203:
  pushl $0
  105ae6:	6a 00                	push   $0x0
  pushl $203
  105ae8:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
  105aed:	e9 5e f3 ff ff       	jmp    104e50 <alltraps>

00105af2 <vector204>:
.globl vector204
vector204:
  pushl $0
  105af2:	6a 00                	push   $0x0
  pushl $204
  105af4:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
  105af9:	e9 52 f3 ff ff       	jmp    104e50 <alltraps>

00105afe <vector205>:
.globl vector205
vector205:
  pushl $0
  105afe:	6a 00                	push   $0x0
  pushl $205
  105b00:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
  105b05:	e9 46 f3 ff ff       	jmp    104e50 <alltraps>

00105b0a <vector206>:
.globl vector206
vector206:
  pushl $0
  105b0a:	6a 00                	push   $0x0
  pushl $206
  105b0c:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
  105b11:	e9 3a f3 ff ff       	jmp    104e50 <alltraps>

00105b16 <vector207>:
.globl vector207
vector207:
  pushl $0
  105b16:	6a 00                	push   $0x0
  pushl $207
  105b18:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
  105b1d:	e9 2e f3 ff ff       	jmp    104e50 <alltraps>

00105b22 <vector208>:
.globl vector208
vector208:
  pushl $0
  105b22:	6a 00                	push   $0x0
  pushl $208
  105b24:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
  105b29:	e9 22 f3 ff ff       	jmp    104e50 <alltraps>

00105b2e <vector209>:
.globl vector209
vector209:
  pushl $0
  105b2e:	6a 00                	push   $0x0
  pushl $209
  105b30:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
  105b35:	e9 16 f3 ff ff       	jmp    104e50 <alltraps>

00105b3a <vector210>:
.globl vector210
vector210:
  pushl $0
  105b3a:	6a 00                	push   $0x0
  pushl $210
  105b3c:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
  105b41:	e9 0a f3 ff ff       	jmp    104e50 <alltraps>

00105b46 <vector211>:
.globl vector211
vector211:
  pushl $0
  105b46:	6a 00                	push   $0x0
  pushl $211
  105b48:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
  105b4d:	e9 fe f2 ff ff       	jmp    104e50 <alltraps>

00105b52 <vector212>:
.globl vector212
vector212:
  pushl $0
  105b52:	6a 00                	push   $0x0
  pushl $212
  105b54:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
  105b59:	e9 f2 f2 ff ff       	jmp    104e50 <alltraps>

00105b5e <vector213>:
.globl vector213
vector213:
  pushl $0
  105b5e:	6a 00                	push   $0x0
  pushl $213
  105b60:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
  105b65:	e9 e6 f2 ff ff       	jmp    104e50 <alltraps>

00105b6a <vector214>:
.globl vector214
vector214:
  pushl $0
  105b6a:	6a 00                	push   $0x0
  pushl $214
  105b6c:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
  105b71:	e9 da f2 ff ff       	jmp    104e50 <alltraps>

00105b76 <vector215>:
.globl vector215
vector215:
  pushl $0
  105b76:	6a 00                	push   $0x0
  pushl $215
  105b78:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
  105b7d:	e9 ce f2 ff ff       	jmp    104e50 <alltraps>

00105b82 <vector216>:
.globl vector216
vector216:
  pushl $0
  105b82:	6a 00                	push   $0x0
  pushl $216
  105b84:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
  105b89:	e9 c2 f2 ff ff       	jmp    104e50 <alltraps>

00105b8e <vector217>:
.globl vector217
vector217:
  pushl $0
  105b8e:	6a 00                	push   $0x0
  pushl $217
  105b90:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
  105b95:	e9 b6 f2 ff ff       	jmp    104e50 <alltraps>

00105b9a <vector218>:
.globl vector218
vector218:
  pushl $0
  105b9a:	6a 00                	push   $0x0
  pushl $218
  105b9c:	68 da 00 00 00       	push   $0xda
  jmp alltraps
  105ba1:	e9 aa f2 ff ff       	jmp    104e50 <alltraps>

00105ba6 <vector219>:
.globl vector219
vector219:
  pushl $0
  105ba6:	6a 00                	push   $0x0
  pushl $219
  105ba8:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
  105bad:	e9 9e f2 ff ff       	jmp    104e50 <alltraps>

00105bb2 <vector220>:
.globl vector220
vector220:
  pushl $0
  105bb2:	6a 00                	push   $0x0
  pushl $220
  105bb4:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
  105bb9:	e9 92 f2 ff ff       	jmp    104e50 <alltraps>

00105bbe <vector221>:
.globl vector221
vector221:
  pushl $0
  105bbe:	6a 00                	push   $0x0
  pushl $221
  105bc0:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
  105bc5:	e9 86 f2 ff ff       	jmp    104e50 <alltraps>

00105bca <vector222>:
.globl vector222
vector222:
  pushl $0
  105bca:	6a 00                	push   $0x0
  pushl $222
  105bcc:	68 de 00 00 00       	push   $0xde
  jmp alltraps
  105bd1:	e9 7a f2 ff ff       	jmp    104e50 <alltraps>

00105bd6 <vector223>:
.globl vector223
vector223:
  pushl $0
  105bd6:	6a 00                	push   $0x0
  pushl $223
  105bd8:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
  105bdd:	e9 6e f2 ff ff       	jmp    104e50 <alltraps>

00105be2 <vector224>:
.globl vector224
vector224:
  pushl $0
  105be2:	6a 00                	push   $0x0
  pushl $224
  105be4:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
  105be9:	e9 62 f2 ff ff       	jmp    104e50 <alltraps>

00105bee <vector225>:
.globl vector225
vector225:
  pushl $0
  105bee:	6a 00                	push   $0x0
  pushl $225
  105bf0:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
  105bf5:	e9 56 f2 ff ff       	jmp    104e50 <alltraps>

00105bfa <vector226>:
.globl vector226
vector226:
  pushl $0
  105bfa:	6a 00                	push   $0x0
  pushl $226
  105bfc:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
  105c01:	e9 4a f2 ff ff       	jmp    104e50 <alltraps>

00105c06 <vector227>:
.globl vector227
vector227:
  pushl $0
  105c06:	6a 00                	push   $0x0
  pushl $227
  105c08:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
  105c0d:	e9 3e f2 ff ff       	jmp    104e50 <alltraps>

00105c12 <vector228>:
.globl vector228
vector228:
  pushl $0
  105c12:	6a 00                	push   $0x0
  pushl $228
  105c14:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
  105c19:	e9 32 f2 ff ff       	jmp    104e50 <alltraps>

00105c1e <vector229>:
.globl vector229
vector229:
  pushl $0
  105c1e:	6a 00                	push   $0x0
  pushl $229
  105c20:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
  105c25:	e9 26 f2 ff ff       	jmp    104e50 <alltraps>

00105c2a <vector230>:
.globl vector230
vector230:
  pushl $0
  105c2a:	6a 00                	push   $0x0
  pushl $230
  105c2c:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
  105c31:	e9 1a f2 ff ff       	jmp    104e50 <alltraps>

00105c36 <vector231>:
.globl vector231
vector231:
  pushl $0
  105c36:	6a 00                	push   $0x0
  pushl $231
  105c38:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
  105c3d:	e9 0e f2 ff ff       	jmp    104e50 <alltraps>

00105c42 <vector232>:
.globl vector232
vector232:
  pushl $0
  105c42:	6a 00                	push   $0x0
  pushl $232
  105c44:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
  105c49:	e9 02 f2 ff ff       	jmp    104e50 <alltraps>

00105c4e <vector233>:
.globl vector233
vector233:
  pushl $0
  105c4e:	6a 00                	push   $0x0
  pushl $233
  105c50:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
  105c55:	e9 f6 f1 ff ff       	jmp    104e50 <alltraps>

00105c5a <vector234>:
.globl vector234
vector234:
  pushl $0
  105c5a:	6a 00                	push   $0x0
  pushl $234
  105c5c:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
  105c61:	e9 ea f1 ff ff       	jmp    104e50 <alltraps>

00105c66 <vector235>:
.globl vector235
vector235:
  pushl $0
  105c66:	6a 00                	push   $0x0
  pushl $235
  105c68:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
  105c6d:	e9 de f1 ff ff       	jmp    104e50 <alltraps>

00105c72 <vector236>:
.globl vector236
vector236:
  pushl $0
  105c72:	6a 00                	push   $0x0
  pushl $236
  105c74:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
  105c79:	e9 d2 f1 ff ff       	jmp    104e50 <alltraps>

00105c7e <vector237>:
.globl vector237
vector237:
  pushl $0
  105c7e:	6a 00                	push   $0x0
  pushl $237
  105c80:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
  105c85:	e9 c6 f1 ff ff       	jmp    104e50 <alltraps>

00105c8a <vector238>:
.globl vector238
vector238:
  pushl $0
  105c8a:	6a 00                	push   $0x0
  pushl $238
  105c8c:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
  105c91:	e9 ba f1 ff ff       	jmp    104e50 <alltraps>

00105c96 <vector239>:
.globl vector239
vector239:
  pushl $0
  105c96:	6a 00                	push   $0x0
  pushl $239
  105c98:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
  105c9d:	e9 ae f1 ff ff       	jmp    104e50 <alltraps>

00105ca2 <vector240>:
.globl vector240
vector240:
  pushl $0
  105ca2:	6a 00                	push   $0x0
  pushl $240
  105ca4:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
  105ca9:	e9 a2 f1 ff ff       	jmp    104e50 <alltraps>

00105cae <vector241>:
.globl vector241
vector241:
  pushl $0
  105cae:	6a 00                	push   $0x0
  pushl $241
  105cb0:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
  105cb5:	e9 96 f1 ff ff       	jmp    104e50 <alltraps>

00105cba <vector242>:
.globl vector242
vector242:
  pushl $0
  105cba:	6a 00                	push   $0x0
  pushl $242
  105cbc:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
  105cc1:	e9 8a f1 ff ff       	jmp    104e50 <alltraps>

00105cc6 <vector243>:
.globl vector243
vector243:
  pushl $0
  105cc6:	6a 00                	push   $0x0
  pushl $243
  105cc8:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
  105ccd:	e9 7e f1 ff ff       	jmp    104e50 <alltraps>

00105cd2 <vector244>:
.globl vector244
vector244:
  pushl $0
  105cd2:	6a 00                	push   $0x0
  pushl $244
  105cd4:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
  105cd9:	e9 72 f1 ff ff       	jmp    104e50 <alltraps>

00105cde <vector245>:
.globl vector245
vector245:
  pushl $0
  105cde:	6a 00                	push   $0x0
  pushl $245
  105ce0:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
  105ce5:	e9 66 f1 ff ff       	jmp    104e50 <alltraps>

00105cea <vector246>:
.globl vector246
vector246:
  pushl $0
  105cea:	6a 00                	push   $0x0
  pushl $246
  105cec:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
  105cf1:	e9 5a f1 ff ff       	jmp    104e50 <alltraps>

00105cf6 <vector247>:
.globl vector247
vector247:
  pushl $0
  105cf6:	6a 00                	push   $0x0
  pushl $247
  105cf8:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
  105cfd:	e9 4e f1 ff ff       	jmp    104e50 <alltraps>

00105d02 <vector248>:
.globl vector248
vector248:
  pushl $0
  105d02:	6a 00                	push   $0x0
  pushl $248
  105d04:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
  105d09:	e9 42 f1 ff ff       	jmp    104e50 <alltraps>

00105d0e <vector249>:
.globl vector249
vector249:
  pushl $0
  105d0e:	6a 00                	push   $0x0
  pushl $249
  105d10:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
  105d15:	e9 36 f1 ff ff       	jmp    104e50 <alltraps>

00105d1a <vector250>:
.globl vector250
vector250:
  pushl $0
  105d1a:	6a 00                	push   $0x0
  pushl $250
  105d1c:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
  105d21:	e9 2a f1 ff ff       	jmp    104e50 <alltraps>

00105d26 <vector251>:
.globl vector251
vector251:
  pushl $0
  105d26:	6a 00                	push   $0x0
  pushl $251
  105d28:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
  105d2d:	e9 1e f1 ff ff       	jmp    104e50 <alltraps>

00105d32 <vector252>:
.globl vector252
vector252:
  pushl $0
  105d32:	6a 00                	push   $0x0
  pushl $252
  105d34:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
  105d39:	e9 12 f1 ff ff       	jmp    104e50 <alltraps>

00105d3e <vector253>:
.globl vector253
vector253:
  pushl $0
  105d3e:	6a 00                	push   $0x0
  pushl $253
  105d40:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
  105d45:	e9 06 f1 ff ff       	jmp    104e50 <alltraps>

00105d4a <vector254>:
.globl vector254
vector254:
  pushl $0
  105d4a:	6a 00                	push   $0x0
  pushl $254
  105d4c:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
  105d51:	e9 fa f0 ff ff       	jmp    104e50 <alltraps>

00105d56 <vector255>:
.globl vector255
vector255:
  pushl $0
  105d56:	6a 00                	push   $0x0
  pushl $255
  105d58:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
  105d5d:	e9 ee f0 ff ff       	jmp    104e50 <alltraps>
  105d62:	90                   	nop
  105d63:	90                   	nop
  105d64:	90                   	nop
  105d65:	90                   	nop
  105d66:	90                   	nop
  105d67:	90                   	nop
  105d68:	90                   	nop
  105d69:	90                   	nop
  105d6a:	90                   	nop
  105d6b:	90                   	nop
  105d6c:	90                   	nop
  105d6d:	90                   	nop
  105d6e:	90                   	nop
  105d6f:	90                   	nop

00105d70 <vmenable>:
}

// Turn on paging.
void
vmenable(void)
{
  105d70:	55                   	push   %ebp
}

static inline void
lcr3(uint val) 
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
  105d71:	a1 d0 78 10 00       	mov    0x1078d0,%eax
  105d76:	89 e5                	mov    %esp,%ebp
  105d78:	0f 22 d8             	mov    %eax,%cr3

static inline uint
rcr0(void)
{
  uint val;
  asm volatile("movl %%cr0,%0" : "=r" (val));
  105d7b:	0f 20 c0             	mov    %cr0,%eax
}

static inline void
lcr0(uint val)
{
  asm volatile("movl %0,%%cr0" : : "r" (val));
  105d7e:	0d 00 00 00 80       	or     $0x80000000,%eax
  105d83:	0f 22 c0             	mov    %eax,%cr0

  switchkvm(); // load kpgdir into cr3
  cr0 = rcr0();
  cr0 |= CR0_PG;
  lcr0(cr0);
}
  105d86:	5d                   	pop    %ebp
  105d87:	c3                   	ret    
  105d88:	90                   	nop
  105d89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

00105d90 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
  105d90:	55                   	push   %ebp
}

static inline void
lcr3(uint val) 
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
  105d91:	a1 d0 78 10 00       	mov    0x1078d0,%eax
  105d96:	89 e5                	mov    %esp,%ebp
  105d98:	0f 22 d8             	mov    %eax,%cr3
  lcr3(PADDR(kpgdir));   // switch to the kernel page table
}
  105d9b:	5d                   	pop    %ebp
  105d9c:	c3                   	ret    
  105d9d:	8d 76 00             	lea    0x0(%esi),%esi

00105da0 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to linear address va.  If create!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int create)
{
  105da0:	55                   	push   %ebp
  105da1:	89 e5                	mov    %esp,%ebp
  105da3:	83 ec 28             	sub    $0x28,%esp
  105da6:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
  105da9:	89 d3                	mov    %edx,%ebx
  105dab:	c1 eb 16             	shr    $0x16,%ebx
  105dae:	8d 1c 98             	lea    (%eax,%ebx,4),%ebx
// Return the address of the PTE in page table pgdir
// that corresponds to linear address va.  If create!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int create)
{
  105db1:	89 75 fc             	mov    %esi,-0x4(%ebp)
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
  if(*pde & PTE_P){
  105db4:	8b 33                	mov    (%ebx),%esi
  105db6:	f7 c6 01 00 00 00    	test   $0x1,%esi
  105dbc:	74 22                	je     105de0 <walkpgdir+0x40>
    pgtab = (pte_t*)PTE_ADDR(*pde);
  105dbe:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = PADDR(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
  105dc4:	c1 ea 0a             	shr    $0xa,%edx
  105dc7:	81 e2 fc 0f 00 00    	and    $0xffc,%edx
  105dcd:	8d 04 16             	lea    (%esi,%edx,1),%eax
}
  105dd0:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  105dd3:	8b 75 fc             	mov    -0x4(%ebp),%esi
  105dd6:	89 ec                	mov    %ebp,%esp
  105dd8:	5d                   	pop    %ebp
  105dd9:	c3                   	ret    
  105dda:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

  pde = &pgdir[PDX(va)];
  if(*pde & PTE_P){
    pgtab = (pte_t*)PTE_ADDR(*pde);
  } else {
    if(!create || (pgtab = (pte_t*)kalloc()) == 0)
  105de0:	85 c9                	test   %ecx,%ecx
  105de2:	75 04                	jne    105de8 <walkpgdir+0x48>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = PADDR(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
  105de4:	31 c0                	xor    %eax,%eax
  105de6:	eb e8                	jmp    105dd0 <walkpgdir+0x30>

  pde = &pgdir[PDX(va)];
  if(*pde & PTE_P){
    pgtab = (pte_t*)PTE_ADDR(*pde);
  } else {
    if(!create || (pgtab = (pte_t*)kalloc()) == 0)
  105de8:	89 55 f4             	mov    %edx,-0xc(%ebp)
  105deb:	90                   	nop
  105dec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105df0:	e8 5b c4 ff ff       	call   102250 <kalloc>
  105df5:	85 c0                	test   %eax,%eax
  105df7:	89 c6                	mov    %eax,%esi
  105df9:	74 e9                	je     105de4 <walkpgdir+0x44>
      return 0;
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
  105dfb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105e02:	00 
  105e03:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105e0a:	00 
  105e0b:	89 04 24             	mov    %eax,(%esp)
  105e0e:	e8 0d df ff ff       	call   103d20 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = PADDR(pgtab) | PTE_P | PTE_W | PTE_U;
  105e13:	89 f0                	mov    %esi,%eax
  105e15:	83 c8 07             	or     $0x7,%eax
  105e18:	89 03                	mov    %eax,(%ebx)
  105e1a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105e1d:	eb a5                	jmp    105dc4 <walkpgdir+0x24>
  105e1f:	90                   	nop

00105e20 <uva2ka>:
}

// Map user virtual address to kernel physical address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
  105e20:	55                   	push   %ebp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
  105e21:	31 c9                	xor    %ecx,%ecx
}

// Map user virtual address to kernel physical address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
  105e23:	89 e5                	mov    %esp,%ebp
  105e25:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
  105e28:	8b 55 0c             	mov    0xc(%ebp),%edx
  105e2b:	8b 45 08             	mov    0x8(%ebp),%eax
  105e2e:	e8 6d ff ff ff       	call   105da0 <walkpgdir>
  if((*pte & PTE_P) == 0)
  105e33:	8b 00                	mov    (%eax),%eax
  105e35:	a8 01                	test   $0x1,%al
  105e37:	75 07                	jne    105e40 <uva2ka+0x20>
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  return (char*)PTE_ADDR(*pte);
  105e39:	31 c0                	xor    %eax,%eax
}
  105e3b:	c9                   	leave  
  105e3c:	c3                   	ret    
  105e3d:	8d 76 00             	lea    0x0(%esi),%esi
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
  if((*pte & PTE_P) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
  105e40:	a8 04                	test   $0x4,%al
  105e42:	74 f5                	je     105e39 <uva2ka+0x19>
    return 0;
  return (char*)PTE_ADDR(*pte);
  105e44:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
  105e49:	c9                   	leave  
  105e4a:	c3                   	ret    
  105e4b:	90                   	nop
  105e4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00105e50 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
  105e50:	55                   	push   %ebp
  105e51:	89 e5                	mov    %esp,%ebp
  105e53:	57                   	push   %edi
  105e54:	56                   	push   %esi
  105e55:	53                   	push   %ebx
  105e56:	83 ec 2c             	sub    $0x2c,%esp
  105e59:	8b 5d 14             	mov    0x14(%ebp),%ebx
  105e5c:	8b 55 0c             	mov    0xc(%ebp),%edx
  char *buf, *pa0;
  uint n, va0;
  
  buf = (char*)p;
  while(len > 0){
  105e5f:	85 db                	test   %ebx,%ebx
  105e61:	74 75                	je     105ed8 <copyout+0x88>
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
  char *buf, *pa0;
  uint n, va0;
  
  buf = (char*)p;
  105e63:	8b 45 10             	mov    0x10(%ebp),%eax
  105e66:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  105e69:	eb 39                	jmp    105ea4 <copyout+0x54>
  105e6b:	90                   	nop
  105e6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  while(len > 0){
    va0 = (uint)PGROUNDDOWN(va);
    pa0 = uva2ka(pgdir, (char*)va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
  105e70:	89 f7                	mov    %esi,%edi
  105e72:	29 d7                	sub    %edx,%edi
  105e74:	81 c7 00 10 00 00    	add    $0x1000,%edi
  105e7a:	39 df                	cmp    %ebx,%edi
  105e7c:	0f 47 fb             	cmova  %ebx,%edi
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
  105e7f:	29 f2                	sub    %esi,%edx
  105e81:	89 7c 24 08          	mov    %edi,0x8(%esp)
  105e85:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  105e88:	8d 14 10             	lea    (%eax,%edx,1),%edx
  105e8b:	89 14 24             	mov    %edx,(%esp)
  105e8e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  105e92:	e8 09 df ff ff       	call   103da0 <memmove>
{
  char *buf, *pa0;
  uint n, va0;
  
  buf = (char*)p;
  while(len > 0){
  105e97:	29 fb                	sub    %edi,%ebx
  105e99:	74 3d                	je     105ed8 <copyout+0x88>
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
  105e9b:	01 7d e4             	add    %edi,-0x1c(%ebp)
    va = va0 + PGSIZE;
  105e9e:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
  char *buf, *pa0;
  uint n, va0;
  
  buf = (char*)p;
  while(len > 0){
    va0 = (uint)PGROUNDDOWN(va);
  105ea4:	89 d6                	mov    %edx,%esi
  105ea6:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
  105eac:	89 74 24 04          	mov    %esi,0x4(%esp)
  105eb0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  105eb3:	89 0c 24             	mov    %ecx,(%esp)
  105eb6:	89 55 e0             	mov    %edx,-0x20(%ebp)
  105eb9:	e8 62 ff ff ff       	call   105e20 <uva2ka>
    if(pa0 == 0)
  105ebe:	8b 55 e0             	mov    -0x20(%ebp),%edx
  105ec1:	85 c0                	test   %eax,%eax
  105ec3:	75 ab                	jne    105e70 <copyout+0x20>
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
}
  105ec5:	83 c4 2c             	add    $0x2c,%esp
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  105ec8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
  105ecd:	5b                   	pop    %ebx
  105ece:	5e                   	pop    %esi
  105ecf:	5f                   	pop    %edi
  105ed0:	5d                   	pop    %ebp
  105ed1:	c3                   	ret    
  105ed2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  105ed8:	83 c4 2c             	add    $0x2c,%esp
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  105edb:	31 c0                	xor    %eax,%eax
  }
  return 0;
}
  105edd:	5b                   	pop    %ebx
  105ede:	5e                   	pop    %esi
  105edf:	5f                   	pop    %edi
  105ee0:	5d                   	pop    %ebp
  105ee1:	c3                   	ret    
  105ee2:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  105ee9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00105ef0 <mappages>:
// Create PTEs for linear addresses starting at la that refer to
// physical addresses starting at pa. la and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *la, uint size, uint pa, int perm)
{
  105ef0:	55                   	push   %ebp
  105ef1:	89 e5                	mov    %esp,%ebp
  105ef3:	57                   	push   %edi
  105ef4:	56                   	push   %esi
  105ef5:	53                   	push   %ebx
  char *a, *last;
  pte_t *pte;
  
  a = PGROUNDDOWN(la);
  105ef6:	89 d3                	mov    %edx,%ebx
  last = PGROUNDDOWN(la + size - 1);
  105ef8:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
// Create PTEs for linear addresses starting at la that refer to
// physical addresses starting at pa. la and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *la, uint size, uint pa, int perm)
{
  105efc:	83 ec 2c             	sub    $0x2c,%esp
  105eff:	8b 75 08             	mov    0x8(%ebp),%esi
  105f02:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  char *a, *last;
  pte_t *pte;
  
  a = PGROUNDDOWN(la);
  105f05:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = PGROUNDDOWN(la + size - 1);
  105f0b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    pte = walkpgdir(pgdir, a, 1);
    if(pte == 0)
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
  105f11:	83 4d 0c 01          	orl    $0x1,0xc(%ebp)
  105f15:	eb 1d                	jmp    105f34 <mappages+0x44>
  105f17:	90                   	nop
  last = PGROUNDDOWN(la + size - 1);
  for(;;){
    pte = walkpgdir(pgdir, a, 1);
    if(pte == 0)
      return -1;
    if(*pte & PTE_P)
  105f18:	f6 00 01             	testb  $0x1,(%eax)
  105f1b:	75 45                	jne    105f62 <mappages+0x72>
      panic("remap");
    *pte = pa | perm | PTE_P;
  105f1d:	8b 55 0c             	mov    0xc(%ebp),%edx
  105f20:	09 f2                	or     %esi,%edx
    if(a == last)
  105f22:	39 fb                	cmp    %edi,%ebx
    pte = walkpgdir(pgdir, a, 1);
    if(pte == 0)
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
  105f24:	89 10                	mov    %edx,(%eax)
    if(a == last)
  105f26:	74 30                	je     105f58 <mappages+0x68>
      break;
    a += PGSIZE;
  105f28:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
  105f2e:	81 c6 00 10 00 00    	add    $0x1000,%esi
  pte_t *pte;
  
  a = PGROUNDDOWN(la);
  last = PGROUNDDOWN(la + size - 1);
  for(;;){
    pte = walkpgdir(pgdir, a, 1);
  105f34:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105f37:	b9 01 00 00 00       	mov    $0x1,%ecx
  105f3c:	89 da                	mov    %ebx,%edx
  105f3e:	e8 5d fe ff ff       	call   105da0 <walkpgdir>
    if(pte == 0)
  105f43:	85 c0                	test   %eax,%eax
  105f45:	75 d1                	jne    105f18 <mappages+0x28>
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}
  105f47:	83 c4 2c             	add    $0x2c,%esp
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  105f4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  return 0;
}
  105f4f:	5b                   	pop    %ebx
  105f50:	5e                   	pop    %esi
  105f51:	5f                   	pop    %edi
  105f52:	5d                   	pop    %ebp
  105f53:	c3                   	ret    
  105f54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105f58:	83 c4 2c             	add    $0x2c,%esp
    if(pte == 0)
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
  105f5b:	31 c0                	xor    %eax,%eax
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}
  105f5d:	5b                   	pop    %ebx
  105f5e:	5e                   	pop    %esi
  105f5f:	5f                   	pop    %edi
  105f60:	5d                   	pop    %ebp
  105f61:	c3                   	ret    
  for(;;){
    pte = walkpgdir(pgdir, a, 1);
    if(pte == 0)
      return -1;
    if(*pte & PTE_P)
      panic("remap");
  105f62:	c7 04 24 f0 6d 10 00 	movl   $0x106df0,(%esp)
  105f69:	e8 b2 a9 ff ff       	call   100920 <panic>
  105f6e:	66 90                	xchg   %ax,%ax

00105f70 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
  105f70:	55                   	push   %ebp
  105f71:	89 e5                	mov    %esp,%ebp
  105f73:	56                   	push   %esi
  105f74:	53                   	push   %ebx
  105f75:	83 ec 10             	sub    $0x10,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
  105f78:	e8 d3 c2 ff ff       	call   102250 <kalloc>
  105f7d:	85 c0                	test   %eax,%eax
  105f7f:	89 c6                	mov    %eax,%esi
  105f81:	74 50                	je     105fd3 <setupkvm+0x63>
    return 0;
  memset(pgdir, 0, PGSIZE);
  105f83:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105f8a:	00 
  105f8b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105f92:	00 
  105f93:	89 04 24             	mov    %eax,(%esp)
  105f96:	e8 85 dd ff ff       	call   103d20 <memset>
  k = kmap;
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
  105f9b:	b8 70 77 10 00       	mov    $0x107770,%eax
  105fa0:	3d 40 77 10 00       	cmp    $0x107740,%eax
  105fa5:	76 2c                	jbe    105fd3 <setupkvm+0x63>
  {(void*)0xFE000000, 0,               PTE_W},  // device mappings
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
  105fa7:	bb 40 77 10 00       	mov    $0x107740,%ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  k = kmap;
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->p, k->e - k->p, (uint)k->p, k->perm) < 0)
  105fac:	8b 13                	mov    (%ebx),%edx
  105fae:	8b 4b 04             	mov    0x4(%ebx),%ecx
  105fb1:	8b 43 08             	mov    0x8(%ebx),%eax
  105fb4:	89 14 24             	mov    %edx,(%esp)
  105fb7:	29 d1                	sub    %edx,%ecx
  105fb9:	89 44 24 04          	mov    %eax,0x4(%esp)
  105fbd:	89 f0                	mov    %esi,%eax
  105fbf:	e8 2c ff ff ff       	call   105ef0 <mappages>
  105fc4:	85 c0                	test   %eax,%eax
  105fc6:	78 18                	js     105fe0 <setupkvm+0x70>

  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  k = kmap;
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
  105fc8:	83 c3 0c             	add    $0xc,%ebx
  105fcb:	81 fb 70 77 10 00    	cmp    $0x107770,%ebx
  105fd1:	75 d9                	jne    105fac <setupkvm+0x3c>
    if(mappages(pgdir, k->p, k->e - k->p, (uint)k->p, k->perm) < 0)
      return 0;

  return pgdir;
}
  105fd3:	83 c4 10             	add    $0x10,%esp
  105fd6:	89 f0                	mov    %esi,%eax
  105fd8:	5b                   	pop    %ebx
  105fd9:	5e                   	pop    %esi
  105fda:	5d                   	pop    %ebp
  105fdb:	c3                   	ret    
  105fdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  k = kmap;
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->p, k->e - k->p, (uint)k->p, k->perm) < 0)
  105fe0:	31 f6                	xor    %esi,%esi
      return 0;

  return pgdir;
}
  105fe2:	83 c4 10             	add    $0x10,%esp
  105fe5:	89 f0                	mov    %esi,%eax
  105fe7:	5b                   	pop    %ebx
  105fe8:	5e                   	pop    %esi
  105fe9:	5d                   	pop    %ebp
  105fea:	c3                   	ret    
  105feb:	90                   	nop
  105fec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00105ff0 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
  105ff0:	55                   	push   %ebp
  105ff1:	89 e5                	mov    %esp,%ebp
  105ff3:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
  105ff6:	e8 75 ff ff ff       	call   105f70 <setupkvm>
  105ffb:	a3 d0 78 10 00       	mov    %eax,0x1078d0
}
  106000:	c9                   	leave  
  106001:	c3                   	ret    
  106002:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  106009:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00106010 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
  106010:	55                   	push   %ebp
  106011:	89 e5                	mov    %esp,%ebp
  106013:	83 ec 38             	sub    $0x38,%esp
  106016:	89 75 f8             	mov    %esi,-0x8(%ebp)
  106019:	8b 75 10             	mov    0x10(%ebp),%esi
  10601c:	8b 45 08             	mov    0x8(%ebp),%eax
  10601f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  106022:	8b 7d 0c             	mov    0xc(%ebp),%edi
  106025:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  char *mem;
  
  if(sz >= PGSIZE)
  106028:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
  10602e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  char *mem;
  
  if(sz >= PGSIZE)
  106031:	77 53                	ja     106086 <inituvm+0x76>
    panic("inituvm: more than a page");
  mem = kalloc();
  106033:	e8 18 c2 ff ff       	call   102250 <kalloc>
  memset(mem, 0, PGSIZE);
  106038:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10603f:	00 
  106040:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  106047:	00 
{
  char *mem;
  
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  106048:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
  10604a:	89 04 24             	mov    %eax,(%esp)
  10604d:	e8 ce dc ff ff       	call   103d20 <memset>
  mappages(pgdir, 0, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  106052:	b9 00 10 00 00       	mov    $0x1000,%ecx
  106057:	31 d2                	xor    %edx,%edx
  106059:	89 1c 24             	mov    %ebx,(%esp)
  10605c:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
  106063:	00 
  106064:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  106067:	e8 84 fe ff ff       	call   105ef0 <mappages>
  memmove(mem, init, sz);
  10606c:	89 75 10             	mov    %esi,0x10(%ebp)
}
  10606f:	8b 75 f8             	mov    -0x8(%ebp),%esi
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pgdir, 0, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  memmove(mem, init, sz);
  106072:	89 7d 0c             	mov    %edi,0xc(%ebp)
}
  106075:	8b 7d fc             	mov    -0x4(%ebp),%edi
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pgdir, 0, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  memmove(mem, init, sz);
  106078:	89 5d 08             	mov    %ebx,0x8(%ebp)
}
  10607b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  10607e:	89 ec                	mov    %ebp,%esp
  106080:	5d                   	pop    %ebp
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pgdir, 0, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  memmove(mem, init, sz);
  106081:	e9 1a dd ff ff       	jmp    103da0 <memmove>
inituvm(pde_t *pgdir, char *init, uint sz)
{
  char *mem;
  
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  106086:	c7 04 24 f6 6d 10 00 	movl   $0x106df6,(%esp)
  10608d:	e8 8e a8 ff ff       	call   100920 <panic>
  106092:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  106099:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001060a0 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
  1060a0:	55                   	push   %ebp
  1060a1:	89 e5                	mov    %esp,%ebp
  1060a3:	57                   	push   %edi
  1060a4:	56                   	push   %esi
  1060a5:	53                   	push   %ebx
  1060a6:	83 ec 2c             	sub    $0x2c,%esp
  1060a9:	8b 75 0c             	mov    0xc(%ebp),%esi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
  1060ac:	39 75 10             	cmp    %esi,0x10(%ebp)
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
  1060af:	8b 7d 08             	mov    0x8(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
    return oldsz;
  1060b2:	89 f0                	mov    %esi,%eax
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
  1060b4:	73 59                	jae    10610f <deallocuvm+0x6f>
    return oldsz;

  a = PGROUNDUP(newsz);
  1060b6:	8b 5d 10             	mov    0x10(%ebp),%ebx
  1060b9:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
  1060bf:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
  1060c5:	39 de                	cmp    %ebx,%esi
  1060c7:	76 43                	jbe    10610c <deallocuvm+0x6c>
  1060c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    pte = walkpgdir(pgdir, (char*)a, 0);
  1060d0:	31 c9                	xor    %ecx,%ecx
  1060d2:	89 da                	mov    %ebx,%edx
  1060d4:	89 f8                	mov    %edi,%eax
  1060d6:	e8 c5 fc ff ff       	call   105da0 <walkpgdir>
    if(pte && (*pte & PTE_P) != 0){
  1060db:	85 c0                	test   %eax,%eax
  1060dd:	74 23                	je     106102 <deallocuvm+0x62>
  1060df:	8b 10                	mov    (%eax),%edx
  1060e1:	f6 c2 01             	test   $0x1,%dl
  1060e4:	74 1c                	je     106102 <deallocuvm+0x62>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
  1060e6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  1060ec:	74 29                	je     106117 <deallocuvm+0x77>
        panic("kfree");
      kfree((char*)pa);
  1060ee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1060f1:	89 14 24             	mov    %edx,(%esp)
  1060f4:	e8 97 c1 ff ff       	call   102290 <kfree>
      *pte = 0;
  1060f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1060fc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
  106102:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  106108:	39 de                	cmp    %ebx,%esi
  10610a:	77 c4                	ja     1060d0 <deallocuvm+0x30>
        panic("kfree");
      kfree((char*)pa);
      *pte = 0;
    }
  }
  return newsz;
  10610c:	8b 45 10             	mov    0x10(%ebp),%eax
}
  10610f:	83 c4 2c             	add    $0x2c,%esp
  106112:	5b                   	pop    %ebx
  106113:	5e                   	pop    %esi
  106114:	5f                   	pop    %edi
  106115:	5d                   	pop    %ebp
  106116:	c3                   	ret    
  for(; a  < oldsz; a += PGSIZE){
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(pte && (*pte & PTE_P) != 0){
      pa = PTE_ADDR(*pte);
      if(pa == 0)
        panic("kfree");
  106117:	c7 04 24 9e 67 10 00 	movl   $0x10679e,(%esp)
  10611e:	e8 fd a7 ff ff       	call   100920 <panic>
  106123:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  106129:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00106130 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
  106130:	55                   	push   %ebp
  106131:	89 e5                	mov    %esp,%ebp
  106133:	56                   	push   %esi
  106134:	53                   	push   %ebx
  106135:	83 ec 10             	sub    $0x10,%esp
  106138:	8b 5d 08             	mov    0x8(%ebp),%ebx
  uint i;

  if(pgdir == 0)
  10613b:	85 db                	test   %ebx,%ebx
  10613d:	74 59                	je     106198 <freevm+0x68>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, USERTOP, 0);
  10613f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  106146:	00 
  106147:	31 f6                	xor    %esi,%esi
  106149:	c7 44 24 04 00 00 0a 	movl   $0xa0000,0x4(%esp)
  106150:	00 
  106151:	89 1c 24             	mov    %ebx,(%esp)
  106154:	e8 47 ff ff ff       	call   1060a0 <deallocuvm>
  106159:	eb 10                	jmp    10616b <freevm+0x3b>
  10615b:	90                   	nop
  10615c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  for(i = 0; i < NPDENTRIES; i++){
  106160:	83 c6 01             	add    $0x1,%esi
  106163:	81 fe 00 04 00 00    	cmp    $0x400,%esi
  106169:	74 1f                	je     10618a <freevm+0x5a>
    if(pgdir[i] & PTE_P)
  10616b:	8b 04 b3             	mov    (%ebx,%esi,4),%eax
  10616e:	a8 01                	test   $0x1,%al
  106170:	74 ee                	je     106160 <freevm+0x30>
      kfree((char*)PTE_ADDR(pgdir[i]));
  106172:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, USERTOP, 0);
  for(i = 0; i < NPDENTRIES; i++){
  106177:	83 c6 01             	add    $0x1,%esi
    if(pgdir[i] & PTE_P)
      kfree((char*)PTE_ADDR(pgdir[i]));
  10617a:	89 04 24             	mov    %eax,(%esp)
  10617d:	e8 0e c1 ff ff       	call   102290 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, USERTOP, 0);
  for(i = 0; i < NPDENTRIES; i++){
  106182:	81 fe 00 04 00 00    	cmp    $0x400,%esi
  106188:	75 e1                	jne    10616b <freevm+0x3b>
    if(pgdir[i] & PTE_P)
      kfree((char*)PTE_ADDR(pgdir[i]));
  }
  kfree((char*)pgdir);
  10618a:	89 5d 08             	mov    %ebx,0x8(%ebp)
}
  10618d:	83 c4 10             	add    $0x10,%esp
  106190:	5b                   	pop    %ebx
  106191:	5e                   	pop    %esi
  106192:	5d                   	pop    %ebp
  deallocuvm(pgdir, USERTOP, 0);
  for(i = 0; i < NPDENTRIES; i++){
    if(pgdir[i] & PTE_P)
      kfree((char*)PTE_ADDR(pgdir[i]));
  }
  kfree((char*)pgdir);
  106193:	e9 f8 c0 ff ff       	jmp    102290 <kfree>
freevm(pde_t *pgdir)
{
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  106198:	c7 04 24 10 6e 10 00 	movl   $0x106e10,(%esp)
  10619f:	e8 7c a7 ff ff       	call   100920 <panic>
  1061a4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1061aa:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

001061b0 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
  1061b0:	55                   	push   %ebp
  1061b1:	89 e5                	mov    %esp,%ebp
  1061b3:	57                   	push   %edi
  1061b4:	56                   	push   %esi
  1061b5:	53                   	push   %ebx
  1061b6:	83 ec 2c             	sub    $0x2c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
  1061b9:	e8 b2 fd ff ff       	call   105f70 <setupkvm>
  1061be:	85 c0                	test   %eax,%eax
  1061c0:	89 c6                	mov    %eax,%esi
  1061c2:	0f 84 84 00 00 00    	je     10624c <copyuvm+0x9c>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
  1061c8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1061cb:	85 c0                	test   %eax,%eax
  1061cd:	74 7d                	je     10624c <copyuvm+0x9c>
  1061cf:	31 db                	xor    %ebx,%ebx
  1061d1:	eb 47                	jmp    10621a <copyuvm+0x6a>
  1061d3:	90                   	nop
  1061d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
    memmove(mem, (char*)pa, PGSIZE);
  1061d8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  1061de:	89 54 24 04          	mov    %edx,0x4(%esp)
  1061e2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1061e9:	00 
  1061ea:	89 04 24             	mov    %eax,(%esp)
  1061ed:	e8 ae db ff ff       	call   103da0 <memmove>
    if(mappages(d, (void*)i, PGSIZE, PADDR(mem), PTE_W|PTE_U) < 0)
  1061f2:	b9 00 10 00 00       	mov    $0x1000,%ecx
  1061f7:	89 da                	mov    %ebx,%edx
  1061f9:	89 f0                	mov    %esi,%eax
  1061fb:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
  106202:	00 
  106203:	89 3c 24             	mov    %edi,(%esp)
  106206:	e8 e5 fc ff ff       	call   105ef0 <mappages>
  10620b:	85 c0                	test   %eax,%eax
  10620d:	78 33                	js     106242 <copyuvm+0x92>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
  10620f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  106215:	39 5d 0c             	cmp    %ebx,0xc(%ebp)
  106218:	76 32                	jbe    10624c <copyuvm+0x9c>
    if((pte = walkpgdir(pgdir, (void*)i, 0)) == 0)
  10621a:	8b 45 08             	mov    0x8(%ebp),%eax
  10621d:	31 c9                	xor    %ecx,%ecx
  10621f:	89 da                	mov    %ebx,%edx
  106221:	e8 7a fb ff ff       	call   105da0 <walkpgdir>
  106226:	85 c0                	test   %eax,%eax
  106228:	74 2c                	je     106256 <copyuvm+0xa6>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
  10622a:	8b 10                	mov    (%eax),%edx
  10622c:	f6 c2 01             	test   $0x1,%dl
  10622f:	74 31                	je     106262 <copyuvm+0xb2>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
  106231:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  106234:	e8 17 c0 ff ff       	call   102250 <kalloc>
  106239:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10623c:	85 c0                	test   %eax,%eax
  10623e:	89 c7                	mov    %eax,%edi
  106240:	75 96                	jne    1061d8 <copyuvm+0x28>
      goto bad;
  }
  return d;

bad:
  freevm(d);
  106242:	89 34 24             	mov    %esi,(%esp)
  106245:	31 f6                	xor    %esi,%esi
  106247:	e8 e4 fe ff ff       	call   106130 <freevm>
  return 0;
}
  10624c:	83 c4 2c             	add    $0x2c,%esp
  10624f:	89 f0                	mov    %esi,%eax
  106251:	5b                   	pop    %ebx
  106252:	5e                   	pop    %esi
  106253:	5f                   	pop    %edi
  106254:	5d                   	pop    %ebp
  106255:	c3                   	ret    

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, (void*)i, 0)) == 0)
      panic("copyuvm: pte should exist");
  106256:	c7 04 24 21 6e 10 00 	movl   $0x106e21,(%esp)
  10625d:	e8 be a6 ff ff       	call   100920 <panic>
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
  106262:	c7 04 24 3b 6e 10 00 	movl   $0x106e3b,(%esp)
  106269:	e8 b2 a6 ff ff       	call   100920 <panic>
  10626e:	66 90                	xchg   %ax,%ax

00106270 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
  106270:	55                   	push   %ebp
  char *mem;
  uint a;

  if(newsz > USERTOP)
  106271:	31 c0                	xor    %eax,%eax

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
  106273:	89 e5                	mov    %esp,%ebp
  106275:	57                   	push   %edi
  106276:	56                   	push   %esi
  106277:	53                   	push   %ebx
  106278:	83 ec 2c             	sub    $0x2c,%esp
  10627b:	8b 75 10             	mov    0x10(%ebp),%esi
  10627e:	8b 7d 08             	mov    0x8(%ebp),%edi
  char *mem;
  uint a;

  if(newsz > USERTOP)
  106281:	81 fe 00 00 0a 00    	cmp    $0xa0000,%esi
  106287:	0f 87 8e 00 00 00    	ja     10631b <allocuvm+0xab>
    return 0;
  if(newsz < oldsz)
    return oldsz;
  10628d:	8b 45 0c             	mov    0xc(%ebp),%eax
  char *mem;
  uint a;

  if(newsz > USERTOP)
    return 0;
  if(newsz < oldsz)
  106290:	39 c6                	cmp    %eax,%esi
  106292:	0f 82 83 00 00 00    	jb     10631b <allocuvm+0xab>
    return oldsz;

  a = PGROUNDUP(oldsz);
  106298:	89 c3                	mov    %eax,%ebx
  10629a:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
  1062a0:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
  1062a6:	39 de                	cmp    %ebx,%esi
  1062a8:	77 47                	ja     1062f1 <allocuvm+0x81>
  1062aa:	eb 7c                	jmp    106328 <allocuvm+0xb8>
  1062ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    if(mem == 0){
      cprintf("allocuvm out of memory\n");
      deallocuvm(pgdir, newsz, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
  1062b0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1062b7:	00 
  1062b8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1062bf:	00 
  1062c0:	89 04 24             	mov    %eax,(%esp)
  1062c3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1062c6:	e8 55 da ff ff       	call   103d20 <memset>
    mappages(pgdir, (char*)a, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  1062cb:	b9 00 10 00 00       	mov    $0x1000,%ecx
  1062d0:	89 f8                	mov    %edi,%eax
  1062d2:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
  1062d9:	00 
  1062da:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1062dd:	89 14 24             	mov    %edx,(%esp)
  1062e0:	89 da                	mov    %ebx,%edx
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
  1062e2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
      cprintf("allocuvm out of memory\n");
      deallocuvm(pgdir, newsz, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  1062e8:	e8 03 fc ff ff       	call   105ef0 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
  1062ed:	39 de                	cmp    %ebx,%esi
  1062ef:	76 37                	jbe    106328 <allocuvm+0xb8>
    mem = kalloc();
  1062f1:	e8 5a bf ff ff       	call   102250 <kalloc>
    if(mem == 0){
  1062f6:	85 c0                	test   %eax,%eax
  1062f8:	75 b6                	jne    1062b0 <allocuvm+0x40>
      cprintf("allocuvm out of memory\n");
  1062fa:	c7 04 24 55 6e 10 00 	movl   $0x106e55,(%esp)
  106301:	e8 2a a2 ff ff       	call   100530 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
  106306:	8b 45 0c             	mov    0xc(%ebp),%eax
  106309:	89 74 24 04          	mov    %esi,0x4(%esp)
  10630d:	89 3c 24             	mov    %edi,(%esp)
  106310:	89 44 24 08          	mov    %eax,0x8(%esp)
  106314:	e8 87 fd ff ff       	call   1060a0 <deallocuvm>
  106319:	31 c0                	xor    %eax,%eax
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  }
  return newsz;
}
  10631b:	83 c4 2c             	add    $0x2c,%esp
  10631e:	5b                   	pop    %ebx
  10631f:	5e                   	pop    %esi
  106320:	5f                   	pop    %edi
  106321:	5d                   	pop    %ebp
  106322:	c3                   	ret    
  106323:	90                   	nop
  106324:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  106328:	83 c4 2c             	add    $0x2c,%esp
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, PADDR(mem), PTE_W|PTE_U);
  }
  return newsz;
  10632b:	89 f0                	mov    %esi,%eax
}
  10632d:	5b                   	pop    %ebx
  10632e:	5e                   	pop    %esi
  10632f:	5f                   	pop    %edi
  106330:	5d                   	pop    %ebp
  106331:	c3                   	ret    
  106332:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  106339:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00106340 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
  106340:	55                   	push   %ebp
  106341:	89 e5                	mov    %esp,%ebp
  106343:	57                   	push   %edi
  106344:	56                   	push   %esi
  106345:	53                   	push   %ebx
  106346:	83 ec 2c             	sub    $0x2c,%esp
  106349:	8b 7d 0c             	mov    0xc(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint)addr % PGSIZE != 0)
  10634c:	f7 c7 ff 0f 00 00    	test   $0xfff,%edi
  106352:	0f 85 96 00 00 00    	jne    1063ee <loaduvm+0xae>
    panic("loaduvm: addr must be page aligned");
  106358:	8b 75 18             	mov    0x18(%ebp),%esi
  10635b:	31 db                	xor    %ebx,%ebx
  for(i = 0; i < sz; i += PGSIZE){
  10635d:	85 f6                	test   %esi,%esi
  10635f:	75 18                	jne    106379 <loaduvm+0x39>
  106361:	eb 75                	jmp    1063d8 <loaduvm+0x98>
  106363:	90                   	nop
  106364:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  106368:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  10636e:	81 ee 00 10 00 00    	sub    $0x1000,%esi
  106374:	39 5d 18             	cmp    %ebx,0x18(%ebp)
  106377:	76 5f                	jbe    1063d8 <loaduvm+0x98>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
  106379:	8b 45 08             	mov    0x8(%ebp),%eax
  10637c:	31 c9                	xor    %ecx,%ecx
  10637e:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
  106381:	e8 1a fa ff ff       	call   105da0 <walkpgdir>
  106386:	85 c0                	test   %eax,%eax
  106388:	74 58                	je     1063e2 <loaduvm+0xa2>
      panic("loaduvm: address should exist");
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
  10638a:	81 fe 00 10 00 00    	cmp    $0x1000,%esi
  106390:	ba 00 10 00 00       	mov    $0x1000,%edx
  if((uint)addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
    pa = PTE_ADDR(*pte);
  106395:	8b 00                	mov    (%eax),%eax
    if(sz - i < PGSIZE)
  106397:	0f 42 d6             	cmovb  %esi,%edx
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, (char*)pa, offset+i, n) != n)
  10639a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10639e:	8b 4d 14             	mov    0x14(%ebp),%ecx
  1063a1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1063a6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1063aa:	8d 0c 0b             	lea    (%ebx,%ecx,1),%ecx
  1063ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1063b1:	8b 45 10             	mov    0x10(%ebp),%eax
  1063b4:	89 04 24             	mov    %eax,(%esp)
  1063b7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1063ba:	e8 a1 af ff ff       	call   101360 <readi>
  1063bf:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1063c2:	39 d0                	cmp    %edx,%eax
  1063c4:	74 a2                	je     106368 <loaduvm+0x28>
      return -1;
  }
  return 0;
}
  1063c6:	83 c4 2c             	add    $0x2c,%esp
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, (char*)pa, offset+i, n) != n)
  1063c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
      return -1;
  }
  return 0;
}
  1063ce:	5b                   	pop    %ebx
  1063cf:	5e                   	pop    %esi
  1063d0:	5f                   	pop    %edi
  1063d1:	5d                   	pop    %ebp
  1063d2:	c3                   	ret    
  1063d3:	90                   	nop
  1063d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1063d8:	83 c4 2c             	add    $0x2c,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint)addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
  1063db:	31 c0                	xor    %eax,%eax
      n = PGSIZE;
    if(readi(ip, (char*)pa, offset+i, n) != n)
      return -1;
  }
  return 0;
}
  1063dd:	5b                   	pop    %ebx
  1063de:	5e                   	pop    %esi
  1063df:	5f                   	pop    %edi
  1063e0:	5d                   	pop    %ebp
  1063e1:	c3                   	ret    

  if((uint)addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
  1063e2:	c7 04 24 6d 6e 10 00 	movl   $0x106e6d,(%esp)
  1063e9:	e8 32 a5 ff ff       	call   100920 <panic>
{
  uint i, pa, n;
  pte_t *pte;

  if((uint)addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  1063ee:	c7 04 24 a0 6e 10 00 	movl   $0x106ea0,(%esp)
  1063f5:	e8 26 a5 ff ff       	call   100920 <panic>
  1063fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00106400 <switchuvm>:
}

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
  106400:	55                   	push   %ebp
  106401:	89 e5                	mov    %esp,%ebp
  106403:	53                   	push   %ebx
  106404:	83 ec 14             	sub    $0x14,%esp
  106407:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
  10640a:	e8 81 d7 ff ff       	call   103b90 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
  10640f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  106415:	8d 50 08             	lea    0x8(%eax),%edx
  106418:	89 d1                	mov    %edx,%ecx
  10641a:	66 89 90 a2 00 00 00 	mov    %dx,0xa2(%eax)
  106421:	c1 e9 10             	shr    $0x10,%ecx
  106424:	c1 ea 18             	shr    $0x18,%edx
  106427:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
  10642d:	c6 80 a5 00 00 00 99 	movb   $0x99,0xa5(%eax)
  106434:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  10643a:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
  106441:	67 00 
  106443:	c6 80 a6 00 00 00 40 	movb   $0x40,0xa6(%eax)
  cpu->gdt[SEG_TSS].s = 0;
  10644a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  106450:	80 a0 a5 00 00 00 ef 	andb   $0xef,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
  106457:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  10645d:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
  106463:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  106469:	8b 50 08             	mov    0x8(%eax),%edx
  10646c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
  106472:	81 c2 00 10 00 00    	add    $0x1000,%edx
  106478:	89 50 0c             	mov    %edx,0xc(%eax)
}

static inline void
ltr(ushort sel)
{
  asm volatile("ltr %0" : : "r" (sel));
  10647b:	b8 30 00 00 00       	mov    $0x30,%eax
  106480:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  if(p->pgdir == 0)
  106483:	8b 43 04             	mov    0x4(%ebx),%eax
  106486:	85 c0                	test   %eax,%eax
  106488:	74 0d                	je     106497 <switchuvm+0x97>
}

static inline void
lcr3(uint val) 
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
  10648a:	0f 22 d8             	mov    %eax,%cr3
    panic("switchuvm: no pgdir");
  lcr3(PADDR(p->pgdir));  // switch to new address space
  popcli();
}
  10648d:	83 c4 14             	add    $0x14,%esp
  106490:	5b                   	pop    %ebx
  106491:	5d                   	pop    %ebp
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
  ltr(SEG_TSS << 3);
  if(p->pgdir == 0)
    panic("switchuvm: no pgdir");
  lcr3(PADDR(p->pgdir));  // switch to new address space
  popcli();
  106492:	e9 39 d7 ff ff       	jmp    103bd0 <popcli>
  cpu->gdt[SEG_TSS].s = 0;
  cpu->ts.ss0 = SEG_KDATA << 3;
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
  ltr(SEG_TSS << 3);
  if(p->pgdir == 0)
    panic("switchuvm: no pgdir");
  106497:	c7 04 24 8b 6e 10 00 	movl   $0x106e8b,(%esp)
  10649e:	e8 7d a4 ff ff       	call   100920 <panic>
  1064a3:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1064a9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001064b0 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once at boot time on each CPU.
void
seginit(void)
{
  1064b0:	55                   	push   %ebp
  1064b1:	89 e5                	mov    %esp,%ebp
  1064b3:	83 ec 18             	sub    $0x18,%esp

  // Map virtual addresses to linear addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
  1064b6:	e8 75 c0 ff ff       	call   102530 <cpunum>
  1064bb:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
  1064c1:	05 20 bb 10 00       	add    $0x10bb20,%eax
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
  1064c6:	8d 90 b4 00 00 00    	lea    0xb4(%eax),%edx
  1064cc:	66 89 90 8a 00 00 00 	mov    %dx,0x8a(%eax)
  1064d3:	89 d1                	mov    %edx,%ecx
  1064d5:	c1 ea 18             	shr    $0x18,%edx
  1064d8:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)
  1064de:	c1 e9 10             	shr    $0x10,%ecx

  lgdt(c->gdt, sizeof(c->gdt));
  1064e1:	8d 50 70             	lea    0x70(%eax),%edx
  // Map virtual addresses to linear addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
  1064e4:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
  1064ea:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
  1064f0:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
  1064f4:	c6 40 7d 9a          	movb   $0x9a,0x7d(%eax)
  1064f8:	c6 40 7e cf          	movb   $0xcf,0x7e(%eax)
  1064fc:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
  106500:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
  106507:	ff ff 
  106509:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
  106510:	00 00 
  106512:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
  106519:	c6 80 85 00 00 00 92 	movb   $0x92,0x85(%eax)
  106520:	c6 80 86 00 00 00 cf 	movb   $0xcf,0x86(%eax)
  106527:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
  10652e:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
  106535:	ff ff 
  106537:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
  10653e:	00 00 
  106540:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
  106547:	c6 80 95 00 00 00 fa 	movb   $0xfa,0x95(%eax)
  10654e:	c6 80 96 00 00 00 cf 	movb   $0xcf,0x96(%eax)
  106555:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
  10655c:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
  106563:	ff ff 
  106565:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
  10656c:	00 00 
  10656e:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
  106575:	c6 80 9d 00 00 00 f2 	movb   $0xf2,0x9d(%eax)
  10657c:	c6 80 9e 00 00 00 cf 	movb   $0xcf,0x9e(%eax)
  106583:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
  10658a:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
  106591:	00 00 
  106593:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
  106599:	c6 80 8d 00 00 00 92 	movb   $0x92,0x8d(%eax)
  1065a0:	c6 80 8e 00 00 00 c0 	movb   $0xc0,0x8e(%eax)
static inline void
lgdt(struct segdesc *p, int size)
{
  volatile ushort pd[3];

  pd[0] = size-1;
  1065a7:	66 c7 45 f2 37 00    	movw   $0x37,-0xe(%ebp)
  pd[1] = (uint)p;
  1065ad:	66 89 55 f4          	mov    %dx,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
  1065b1:	c1 ea 10             	shr    $0x10,%edx
  1065b4:	66 89 55 f6          	mov    %dx,-0xa(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
  1065b8:	8d 55 f2             	lea    -0xe(%ebp),%edx
  1065bb:	0f 01 12             	lgdtl  (%edx)
}

static inline void
loadgs(ushort v)
{
  asm volatile("movw %0, %%gs" : : "r" (v));
  1065be:	ba 18 00 00 00       	mov    $0x18,%edx
  1065c3:	8e ea                	mov    %edx,%gs

  lgdt(c->gdt, sizeof(c->gdt));
  loadgs(SEG_KCPU << 3);
  
  // Initialize cpu-local storage.
  cpu = c;
  1065c5:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
  1065cb:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
  1065d2:	00 00 00 00 
}
  1065d6:	c9                   	leave  
  1065d7:	c3                   	ret    
