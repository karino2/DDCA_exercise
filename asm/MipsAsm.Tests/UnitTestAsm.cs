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

        [Test]
        public void TestSw()
        {
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
        public void TestS2s()
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
    }
}