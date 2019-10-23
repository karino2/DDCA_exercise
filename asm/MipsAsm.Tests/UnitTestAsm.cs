using System;
using NUnit.Framework;

namespace MipsAsm.Tests
{
    public class AsmTests
    {
        [SetUp]
        public void Setup()
        {
        }

        readonly Asm target = new Asm();

        [Test]
        public void TestAddi()
        {
            var actual = target.AsmOne("addi $2, $0, 5");
            Assert.AreEqual("20020005", actual);
        }

        [Test]
        public void TestAddi2()
        {
            var actual = target.AsmOne("addi $3, $0, 12");
            Assert.AreEqual("2003000c", actual);
        }

        [Test]
        public void TestAddiNegative()
        {
            var actual = target.AsmOne("addi $7, $3, -9");
            Assert.AreEqual("2067fff7", actual);
        }

        [Test]
        public void TestMuli()
        {
            // op: 001010
            var actual = target.AsmOne("muli $2, $0, 5");
            Assert.AreEqual("28020005", actual);
        }

        [Test]
        public void TestOri()
        {
            var actual = target.AsmOne("ori $2, $0, 5");
            Assert.AreEqual("34020005", actual);
        }

        [Test]
        public void TestAndi()
        {
            var actual = target.AsmOne("andi $2, $0, 5");
            Assert.AreEqual("30020005", actual);
        }

        [Test]
        public void TestLui()
        {
            // 0011 11_00 000_0 0010 0 0 0101 0000  
            var actual = target.AsmOne("lui $2, 80");
            Assert.AreEqual("3c020050", actual);
        }

        [Test]
        public void TestOr()
        {
            var actual = target.AsmOne("or $4, $7, $2");
            Assert.AreEqual("00e22025", actual);
        }

        [Test]
        public void TestAnd()
        {
            var actual = target.AsmOne("and $5, $3, $4");
            Assert.AreEqual("00642824", actual);
        }

        [Test]
        public void TestAdd()
        {
            var actual = target.AsmOne("add $5, $5, $4");
            Assert.AreEqual("00a42820", actual);
        }
        [Test]
        public void TestSub()
        {
            var actual = target.AsmOne("sub $7, $7, $2");
            Assert.AreEqual("00e23822", actual);
        }
        [Test]
        public void TestBeq()
        {
            var actual = target.AsmOne("beq $5, $7, 10");
            Assert.AreEqual("10a7000a", actual);
        }
        [Test]
        public void TestSlt()
        {
            var actual = target.AsmOne("slt $4, $3, $4");
            Assert.AreEqual("0064202a", actual);
        }

        // Sll not supported in processor.
        [Test]
        public void TestSll()
        {
            // op(6), rs(5), rt, rd, shamt(5), funct(6)
            // sll rd, rt, shamt
            var actual = target.AsmOne("sll $4, $3, 5");
            // 0000 00_00 000_0 0011 0010 0_001 01_00 0000
            Assert.AreEqual("00032140", actual);
        }

        [Test]
        public void TestSrl()
        {
            // op(6), rs(5), rt, rd, shamt(5), funct(6)
            // slr rd, rt, shamt
            var actual = target.AsmOne("srl $4, $3, 5");
            // 0000 00_00 000_0 0011 0010 0_001 01_00 0010
            Assert.AreEqual("00032142", actual);
        }

        [Test]
        public void TestSw()
        {
            // sw rt, rs, imm
            // [rs+imm] =[rt]
            var actual = target.AsmOne("sw $7, $3, 68");
            Assert.AreEqual("ac670044", actual);
        }

        [Test]
        public void TestLw()
        {
            var actual = target.AsmOne("lw $2, $0, 80");
            Assert.AreEqual("8c020050", actual);
        }

        [Test]
        public void TestJ()
        {
            var actual = target.AsmOne("j 17");
            Assert.AreEqual("08000011", actual);
        }

        [Test]
        public void TestJLabel()
        {
            var actual = target.AsmOne("j hoge");
            Assert.AreEqual("08000000", actual);
            Assert.AreEqual("hoge", target.needResolve[0].Label);
            Assert.AreEqual(0, target.needResolve[0].Pos);
            target.Clear();
        }

        [Test]
        public void TestStripComment()
        {
            var actual = target.StripComment("j 17 // hello world");
            Assert.AreEqual("j 17", actual);
        }

        [Test]
        public void TestStripComment_NoCommentLineShouldKeepTheSame()
        {
            var actual = target.StripComment("j 17 ");
            Assert.AreEqual("j 17 ", actual);
        }
        [Test]
        public void TestStripComment_CommentOnlyLineBecomesEmpty()
        {
            var actual = target.StripComment("// only comment");
            Assert.AreEqual(String.Empty, actual);
        }


        [Test]
        public void TestLabel_AddMap()
        {
            target.AsmOne("some_label:");
            Assert.IsTrue(target.labelMap.ContainsKey("some_label"));
            Assert.AreEqual(0, target.labelMap["some_label"]);
            target.Clear();
        }

        [Test]
        public void TestD2s()
        {
            // d2s $sramaddr, $dramaddr, #width
            // in binary,
            // op $dramaddr $sramaddr #width
            // op code is 110001 (49)
            var actual = target.AsmOne("d2s $2, $1, 80");
            // 1100 01_00 001_0 0010 ...
            Assert.AreEqual("c4220050", actual);
        }

        [Test]
        public void TestS2d()
        {
            // op code is 111001 (57)
            var actual = target.AsmOne("s2d $2, $1, 80");
            // 1110 01_00 001_0 0010 ...
            Assert.AreEqual("e4220050", actual);
        }

        [Test]
        public void TestDsync()
        {
            // op code is 001100 (12)
            var actual = target.AsmOne("dsync");
            Assert.AreEqual("30000000", actual);
        }

        [Test]
        public void TestResolveLabel_Backward()
        {
            target.Emit(target.AsmOne("addi $3, $0, 5"));
            target.Emit(target.AsmOne("addi $3, $0, 5"));
            target.Emit(target.AsmOne("addi $3, $0, 5"));
            target.AsmOne("hoge:");
            target.Emit(target.AsmOne("addi $3, $0, 5"));
            target.Emit(target.AsmOne("j hoge"));
            target.ResolveLabel();
            Assert.AreEqual("08000003", target.binStore.bins[4]);
            target.Clear();
        }
    }
}