using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

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

        private string AsmI(List<string> args, uint funct)
        {
            uint regRs = RegstrToRegnum(args[1]);
            uint regRt = RegstrToRegnum(args[0]);
            return AsmICommon(args, funct, regRs, regRt);
        }

        private string AsmBeq(List<string> args)
        {
            uint regRs = RegstrToRegnum(args[0]);
            uint regRt = RegstrToRegnum(args[1]);
            return AsmICommon(args, 4, regRs, regRt);
        }

        private string AsmICommon(List<string> args, uint funct, uint regRs, uint regRt)
        {
            uint word = funct << 26;

            word += regRs << 21;
            word += regRt << 16;
            word |= (0xffff & (uint)int.Parse(args[2]));
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

        List<String> SplitArgs(string argstr) {
            return argstr.Split(",").Select(arg => arg.Trim(' ')).ToList();
        }

        public string AsmOne(string line) {
            var nimArg = line.Trim(' ').Split(" ", 2);
            var op = nimArg[0].Trim(' ');
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
            if("beq" == op)
            {
                return AsmBeq(args);
            }
            if("addi" == op) {
                return AsmI(args, 8);
            }
            if("sw" == op)
            {
                return AsmI(args, 43);
            }
            if("lw" == op)
            {
                return AsmI(args, 35);
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
                    var res = assembler.AsmOne(line);
                    if (!String.IsNullOrEmpty(res))
                        sw.WriteLine(res);
                    line = sr.ReadLine();
                }
            }catch(IOException ex) {
                System.Console.WriteLine($"IOException: {ex.Message}");
            }
        }

    }
}
