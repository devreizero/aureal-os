#define X64_PUSHAD    \
        "push %rax\n" \
        "push %rcx\n" \
        "push %rdx\n" \
        "push %rdi\n" \
        "push %rsi\n" \
        "push %r8\n"  \
        "push %r9\n"  \
        "push %r10\n" \
        "push %r11\n"

#define X64_POPAD    \
        "pop %r11\n" \
        "pop %r10\n" \
        "pop %r9\n"  \
        "pop %r8\n"  \
        "pop %rsi\n" \
        "pop %rdi\n" \
        "pop %rdx\n" \
        "pop %rcx\n" \
        "pop %rax\n"

#define ISR_NOERR(n)                    \
__attribute__((naked, section(".isr"))) \
void isr_stub_##n(void) {               \
    __asm__ volatile (                  \
        "push $0\n"                     \
        "push $" #n "\n"                \
        "jmp isr_common_stub\n"         \
    );                                  \
}

#define ISR_ERR(n)                      \
__attribute__((naked, section(".isr"))) \
void isr_stub_##n(void) {               \
    __asm__ volatile (                  \
        "push $" #n "\n"                \
        "jmp isr_common_stub\n"         \
    );                                  \
}

__attribute__((naked, section(".isr")))
void isr_common_stub() {
    __asm__ volatile (
        X64_PUSHAD
        "cld\n"
        "leaq (%rsp), %rdi\n"
        "call exceptionHandler\n"
        X64_POPAD
        "addq $0x10, %rsp\n"
        "iretq\n"
    );
}

ISR_NOERR(0)
ISR_NOERR(1)
ISR_NOERR(2)
ISR_NOERR(3)
ISR_NOERR(4)
ISR_NOERR(5)
ISR_NOERR(6)
ISR_NOERR(7)
ISR_ERR(8)
ISR_NOERR(9)
ISR_ERR(10)
ISR_ERR(11)
ISR_ERR(12)
ISR_ERR(13)
ISR_ERR(14)
ISR_NOERR(15)
ISR_NOERR(16)
ISR_ERR(17)
ISR_NOERR(18)
ISR_NOERR(19)
ISR_NOERR(20)
ISR_NOERR(21)
ISR_NOERR(22)
ISR_NOERR(23)
ISR_NOERR(24)
ISR_NOERR(25)
ISR_NOERR(26)
ISR_NOERR(27)
ISR_NOERR(28)
ISR_NOERR(29)
ISR_ERR(30)
ISR_NOERR(31)

__attribute__((naked, section(".irq")))
void irq_common_stub() {
    __asm__ volatile (
        X64_PUSHAD
        "cld\n"
        "leaq (%rsp), %rdi\n"
        "call irqHandler\n"
        X64_POPAD
        "addq $0x10, %rsp\n"
        "iretq\n"
    );
}

#define IRQ(n)                          \
__attribute__((naked, section(".irq"))) \
void irq_stub_##n(void) {               \
    __asm__ volatile (                  \
        "push $0\n"                     \
        "push $" #n "\n"                \
        "jmp irq_common_stub\n"         \
    );                                  \
}

IRQ(32)
IRQ(33)
IRQ(34)
IRQ(35)
IRQ(36)
IRQ(37)
IRQ(38)
IRQ(39)
IRQ(40)
IRQ(41)
IRQ(42)
IRQ(43)
IRQ(44)
IRQ(45)
IRQ(46)
IRQ(47)
IRQ(48)
IRQ(49)
IRQ(50)
IRQ(51)
IRQ(52)
IRQ(53)
IRQ(54)
IRQ(55)
IRQ(56)
IRQ(57)
IRQ(58)
IRQ(59)
IRQ(60)
IRQ(61)
IRQ(62)
IRQ(63)
IRQ(64)
IRQ(65)
IRQ(66)
IRQ(67)
IRQ(68)
IRQ(69)
IRQ(70)
IRQ(71)
IRQ(72)
IRQ(73)
IRQ(74)
IRQ(75)
IRQ(76)
IRQ(77)
IRQ(78)
IRQ(79)
IRQ(80)
IRQ(81)
IRQ(82)
IRQ(83)
IRQ(84)
IRQ(85)
IRQ(86)
IRQ(87)
IRQ(88)
IRQ(89)
IRQ(90)
IRQ(91)
IRQ(92)
IRQ(93)
IRQ(94)
IRQ(95)
IRQ(96)
IRQ(97)
IRQ(98)
IRQ(99)
IRQ(100)
IRQ(101)
IRQ(102)
IRQ(103)
IRQ(104)
IRQ(105)
IRQ(106)
IRQ(107)
IRQ(108)
IRQ(109)
IRQ(110)
IRQ(111)
IRQ(112)
IRQ(113)
IRQ(114)
IRQ(115)
IRQ(116)
IRQ(117)
IRQ(118)
IRQ(119)
IRQ(120)
IRQ(121)
IRQ(122)
IRQ(123)
IRQ(124)
IRQ(125)
IRQ(126)
IRQ(127)
IRQ(128)
IRQ(129)
IRQ(130)
IRQ(131)
IRQ(132)
IRQ(133)
IRQ(134)
IRQ(135)
IRQ(136)
IRQ(137)
IRQ(138)
IRQ(139)
IRQ(140)
IRQ(141)
IRQ(142)
IRQ(143)
IRQ(144)
IRQ(145)
IRQ(146)
IRQ(147)
IRQ(148)
IRQ(149)
IRQ(150)
IRQ(151)
IRQ(152)
IRQ(153)
IRQ(154)
IRQ(155)
IRQ(156)
IRQ(157)
IRQ(158)
IRQ(159)
IRQ(160)
IRQ(161)
IRQ(162)
IRQ(163)
IRQ(164)
IRQ(165)
IRQ(166)
IRQ(167)
IRQ(168)
IRQ(169)
IRQ(170)
IRQ(171)
IRQ(172)
IRQ(173)
IRQ(174)
IRQ(175)
IRQ(176)
IRQ(177)
IRQ(178)
IRQ(179)
IRQ(180)
IRQ(181)
IRQ(182)
IRQ(183)
IRQ(184)
IRQ(185)
IRQ(186)
IRQ(187)
IRQ(188)
IRQ(189)
IRQ(190)
IRQ(191)
IRQ(192)
IRQ(193)
IRQ(194)
IRQ(195)
IRQ(196)
IRQ(197)
IRQ(198)
IRQ(199)
IRQ(200)
IRQ(201)
IRQ(202)
IRQ(203)
IRQ(204)
IRQ(205)
IRQ(206)
IRQ(207)
IRQ(208)
IRQ(209)
IRQ(210)
IRQ(211)
IRQ(212)
IRQ(213)
IRQ(214)
IRQ(215)
IRQ(216)
IRQ(217)
IRQ(218)
IRQ(219)
IRQ(220)
IRQ(221)
IRQ(222)
IRQ(223)
IRQ(224)
IRQ(225)
IRQ(226)
IRQ(227)
IRQ(228)
IRQ(229)
IRQ(230)
IRQ(231)
IRQ(232)
IRQ(233)
IRQ(234)
IRQ(235)
IRQ(236)
IRQ(237)
IRQ(238)
IRQ(239)
IRQ(240)
IRQ(241)
IRQ(242)
IRQ(243)
IRQ(244)
IRQ(245)
IRQ(246)
IRQ(247)
IRQ(248)
IRQ(249)
IRQ(250)
IRQ(251)
IRQ(252)
IRQ(253)
IRQ(254)
IRQ(255)

#define ISR_PTR(n) isr_stub_##n

void *isr_stub_table[] = {
    ISR_PTR(0),
    ISR_PTR(1),
    ISR_PTR(2),
    ISR_PTR(3),
    ISR_PTR(4),
    ISR_PTR(5),
    ISR_PTR(6),
    ISR_PTR(7),
    ISR_PTR(8),
    ISR_PTR(9),
    ISR_PTR(10),
    ISR_PTR(11),
    ISR_PTR(12),
    ISR_PTR(13),
    ISR_PTR(14),
    ISR_PTR(15),
    ISR_PTR(16),
    ISR_PTR(17),
    ISR_PTR(18),
    ISR_PTR(19),
    ISR_PTR(20),
    ISR_PTR(21),
    ISR_PTR(22),
    ISR_PTR(23),
    ISR_PTR(24),
    ISR_PTR(25),
    ISR_PTR(26),
    ISR_PTR(27),
    ISR_PTR(28),
    ISR_PTR(29),
    ISR_PTR(30),
    ISR_PTR(31),
};

#define IRQ_PTR(n) irq_stub_##n

void *irq_stub_table[] = {
    IRQ_PTR(32),
    IRQ_PTR(33),
    IRQ_PTR(34),
    IRQ_PTR(35),
    IRQ_PTR(36),
    IRQ_PTR(37),
    IRQ_PTR(38),
    IRQ_PTR(39),
    IRQ_PTR(40),
    IRQ_PTR(41),
    IRQ_PTR(42),
    IRQ_PTR(43),
    IRQ_PTR(44),
    IRQ_PTR(45),
    IRQ_PTR(46),
    IRQ_PTR(47),
    IRQ_PTR(48),
    IRQ_PTR(49),
    IRQ_PTR(50),
    IRQ_PTR(51),
    IRQ_PTR(52),
    IRQ_PTR(53),
    IRQ_PTR(54),
    IRQ_PTR(55),
    IRQ_PTR(56),
    IRQ_PTR(57),
    IRQ_PTR(58),
    IRQ_PTR(59),
    IRQ_PTR(60),
    IRQ_PTR(61),
    IRQ_PTR(62),
    IRQ_PTR(63),
    IRQ_PTR(64),
    IRQ_PTR(65),
    IRQ_PTR(66),
    IRQ_PTR(67),
    IRQ_PTR(68),
    IRQ_PTR(69),
    IRQ_PTR(70),
    IRQ_PTR(71),
    IRQ_PTR(72),
    IRQ_PTR(73),
    IRQ_PTR(74),
    IRQ_PTR(75),
    IRQ_PTR(76),
    IRQ_PTR(77),
    IRQ_PTR(78),
    IRQ_PTR(79),
    IRQ_PTR(80),
    IRQ_PTR(81),
    IRQ_PTR(82),
    IRQ_PTR(83),
    IRQ_PTR(84),
    IRQ_PTR(85),
    IRQ_PTR(86),
    IRQ_PTR(87),
    IRQ_PTR(88),
    IRQ_PTR(89),
    IRQ_PTR(90),
    IRQ_PTR(91),
    IRQ_PTR(92),
    IRQ_PTR(93),
    IRQ_PTR(94),
    IRQ_PTR(95),
    IRQ_PTR(96),
    IRQ_PTR(97),
    IRQ_PTR(98),
    IRQ_PTR(99),
    IRQ_PTR(100),
    IRQ_PTR(101),
    IRQ_PTR(102),
    IRQ_PTR(103),
    IRQ_PTR(104),
    IRQ_PTR(105),
    IRQ_PTR(106),
    IRQ_PTR(107),
    IRQ_PTR(108),
    IRQ_PTR(109),
    IRQ_PTR(110),
    IRQ_PTR(111),
    IRQ_PTR(112),
    IRQ_PTR(113),
    IRQ_PTR(114),
    IRQ_PTR(115),
    IRQ_PTR(116),
    IRQ_PTR(117),
    IRQ_PTR(118),
    IRQ_PTR(119),
    IRQ_PTR(120),
    IRQ_PTR(121),
    IRQ_PTR(122),
    IRQ_PTR(123),
    IRQ_PTR(124),
    IRQ_PTR(125),
    IRQ_PTR(126),
    IRQ_PTR(127),
    IRQ_PTR(128),
    IRQ_PTR(129),
    IRQ_PTR(130),
    IRQ_PTR(131),
    IRQ_PTR(132),
    IRQ_PTR(133),
    IRQ_PTR(134),
    IRQ_PTR(135),
    IRQ_PTR(136),
    IRQ_PTR(137),
    IRQ_PTR(138),
    IRQ_PTR(139),
    IRQ_PTR(140),
    IRQ_PTR(141),
    IRQ_PTR(142),
    IRQ_PTR(143),
    IRQ_PTR(144),
    IRQ_PTR(145),
    IRQ_PTR(146),
    IRQ_PTR(147),
    IRQ_PTR(148),
    IRQ_PTR(149),
    IRQ_PTR(150),
    IRQ_PTR(151),
    IRQ_PTR(152),
    IRQ_PTR(153),
    IRQ_PTR(154),
    IRQ_PTR(155),
    IRQ_PTR(156),
    IRQ_PTR(157),
    IRQ_PTR(158),
    IRQ_PTR(159),
    IRQ_PTR(160),
    IRQ_PTR(161),
    IRQ_PTR(162),
    IRQ_PTR(163),
    IRQ_PTR(164),
    IRQ_PTR(165),
    IRQ_PTR(166),
    IRQ_PTR(167),
    IRQ_PTR(168),
    IRQ_PTR(169),
    IRQ_PTR(170),
    IRQ_PTR(171),
    IRQ_PTR(172),
    IRQ_PTR(173),
    IRQ_PTR(174),
    IRQ_PTR(175),
    IRQ_PTR(176),
    IRQ_PTR(177),
    IRQ_PTR(178),
    IRQ_PTR(179),
    IRQ_PTR(180),
    IRQ_PTR(181),
    IRQ_PTR(182),
    IRQ_PTR(183),
    IRQ_PTR(184),
    IRQ_PTR(185),
    IRQ_PTR(186),
    IRQ_PTR(187),
    IRQ_PTR(188),
    IRQ_PTR(189),
    IRQ_PTR(190),
    IRQ_PTR(191),
    IRQ_PTR(192),
    IRQ_PTR(193),
    IRQ_PTR(194),
    IRQ_PTR(195),
    IRQ_PTR(196),
    IRQ_PTR(197),
    IRQ_PTR(198),
    IRQ_PTR(199),
    IRQ_PTR(200),
    IRQ_PTR(201),
    IRQ_PTR(202),
    IRQ_PTR(203),
    IRQ_PTR(204),
    IRQ_PTR(205),
    IRQ_PTR(206),
    IRQ_PTR(207),
    IRQ_PTR(208),
    IRQ_PTR(209),
    IRQ_PTR(210),
    IRQ_PTR(211),
    IRQ_PTR(212),
    IRQ_PTR(213),
    IRQ_PTR(214),
    IRQ_PTR(215),
    IRQ_PTR(216),
    IRQ_PTR(217),
    IRQ_PTR(218),
    IRQ_PTR(219),
    IRQ_PTR(220),
    IRQ_PTR(221),
    IRQ_PTR(222),
    IRQ_PTR(223),
    IRQ_PTR(224),
    IRQ_PTR(225),
    IRQ_PTR(226),
    IRQ_PTR(227),
    IRQ_PTR(228),
    IRQ_PTR(229),
    IRQ_PTR(230),
    IRQ_PTR(231),
    IRQ_PTR(232),
    IRQ_PTR(233),
    IRQ_PTR(234),
    IRQ_PTR(235),
    IRQ_PTR(236),
    IRQ_PTR(237),
    IRQ_PTR(238),
    IRQ_PTR(239),
    IRQ_PTR(240),
    IRQ_PTR(241),
    IRQ_PTR(242),
    IRQ_PTR(243),
    IRQ_PTR(244),
    IRQ_PTR(245),
    IRQ_PTR(246),
    IRQ_PTR(247),
    IRQ_PTR(248),
    IRQ_PTR(249),
    IRQ_PTR(250),
    IRQ_PTR(251),
    IRQ_PTR(252),
    IRQ_PTR(253),
    IRQ_PTR(254),
    IRQ_PTR(255),
};