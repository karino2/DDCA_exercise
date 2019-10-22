using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

/*
Use imm value (digit) instead of label.
Use `sw $7 $3 68` instead of `sw $7 68($3)`. (sw rt rs imm).
Use abs address divided by 4 for j argument. Base is decimal.
 */

namespace MipsAsm
{
    public class Asm
    {
        uint RegstrToRegnum(string regstr) {
            return uint.Parse(regstr.Trim(' ').Substring(1));
        }

        private string AsmI(List<string> args, uint op)
        {
            uint regRs = RegstrToRegnum(args[1]);
            uint regRt = RegstrToRegnum(args[0]);
            return AsmICommon(op, regRs, regRt, args[2]);
        }

        private string AsmLui(List<string> args)
        {
            uint regRt = RegstrToRegnum(args[0]);
            return AsmICommon(15, 0, regRt, args[1]);
        }


        private string AsmBeq(List<string> args)
        {
            uint regRs = RegstrToRegnum(args[0]);
            uint regRt = RegstrToRegnum(args[1]);
            return AsmICommon(4, regRs, regRt, args[2]);
        }

        private string AsmICommon(uint op, uint regRs, uint regRt, String imm)
        {
            uint word = op << 26;

            word += regRs << 21;
            word += regRt << 16;
            word |= (0xffff & (uint)int.Parse(imm));
            return String.Format("{0:x8}", word);
        }

        private string AsmR(List<string> args, uint funct)
        {
            uint word = 0;
            word += RegstrToRegnum(args[0]) << 11;
            word += RegstrToRegnum(args[1]) << 21;
            word += RegstrToRegnum(args[2]) << 16;
            word |= funct;
            return String.Format("{0:x8}", word);
        }

        private string AsmSll(List<string> args)
        {
            /*
            // op(6), rs(5), rt, rd, shamt(5), funct(6)
            // sll rd, rt, shamt
            var actual = target.AsmOne("sll $4, $3, 5");
            // 0000 00_00 000_0 0011 0010 0_001 01_00 0000
             */
            uint word = 0;
            word += RegstrToRegnum(args[0]) << 11;
            word += RegstrToRegnum(args[1]) << 16;
            word += (0xffff & (uint)int.Parse(args[2])) << 6;
            return String.Format("{0:x8}", word);
        }

        List<String> SplitArgs(string argstr) {
            return argstr.Split(",").Select(arg => arg.Trim(' ')).ToList();
        }

        Regex whitePat = new Regex(@"^\s*$");

        bool IsEmptyLine(string line) {
            return whitePat.IsMatch(line);
        }

        public string AsmOne(string line) {
            if(IsEmptyLine(line))
                return String.Empty;

            var nimArg = line.Trim(' ').Split(" ", 2);
            var op = nimArg[0].Trim(' ');
            if("dsync" == op)
            {
                return "30000000";
            }
            if("nop" == op)
            {
                return "00000000";
            }
            if("halt" == op)
            {
                return "38000000";
            }

            var args = SplitArgs(nimArg[1]);
            if("or" == op)
            {
                return AsmR(args, 37);
            }
            if("and" == op)
            {
                return AsmR(args, 36);
            }
            if("add" == op)
            {
                return AsmR(args, 32);
            }
            if("sub" == op)
            {
                return AsmR(args, 34);
            }
            if("slt" == op)
            {
                return AsmR(args, 42);
            }
            // Sll not supported in processor.
            if("sll" == op)
            {
                return AsmSll(args);
            }
            if("beq" == op)
            {
                return AsmBeq(args);
            }
            if("addi" == op) {
                return AsmI(args, 8);
            }
            if("muli" == op) {
                return AsmI(args, 10);
            }
            if("ori" == op) {
                return AsmI(args, 13);
            }
            if("sw" == op)
            {
                return AsmI(args, 43);
            }
            if("lw" == op)
            {
                return AsmI(args, 35);
            }
            if("d2s" == op)
            {
                return AsmI(args, 49);
            }
            if("s2d" == op)
            {
                return AsmI(args, 57);
            }
            if("lui" == op) {
                return AsmLui(args);
            }
            if("j" == op)
            {
                uint word = 2 << 26;

                word |= (0x3ffffff & (uint)int.Parse(args[0]));
                return String.Format("{0:x8}", word);
            }
            return String.Empty;
        }

        public string StripComment(string line)
        {
            var parts = line.Split("//", 2);
            if(parts.Length != 2)
                return line;
            return parts[0].Trim(' ');
        }

        static void Main(string[] args)
        {
            if(args.Length != 1)
            {
                System.Console.WriteLine("Usage: mips_asm.exe asmfile.s");
                System.Console.WriteLine("");
                System.Console.WriteLine("Output file is asmfile.mem");
                return;
            }
            var output = Path.Combine(
                Path.GetDirectoryName(args[0]),
                Path.GetFileNameWithoutExtension(args[0])+".mem"
            );
            System.Console.WriteLine($"output={output}");
            var assembler = new Asm();        

            try {
                using var sr = new StreamReader(args[0]);
                using var sw = new StreamWriter(output);

                var line = sr.ReadLine();
                while (line != null)
                {
                    line = assembler.StripComment(line);
                    try {
                        var res = assembler.AsmOne(line);
                        if (!String.IsNullOrEmpty(res))
                            sw.WriteLine(res);
                        line = sr.ReadLine();
                    }catch(System.IndexOutOfRangeException exi) {
                        System.Console.WriteLine($"Index out of range exception: line: {line}, ex: {exi.Message}");
                        return;
                    }
                }
            }catch(IOException ex) {
                System.Console.WriteLine($"IOException: {ex.Message}");
            }
        }

    }
}
