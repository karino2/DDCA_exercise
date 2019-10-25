# Tiny SIMD for Arty FPGA

karino2が勉強の為に作った 4コアのSIMTプロセッサ+DDR+jtagでのアクセス を合わせた物です。
詳細は以下のブログを参考の事。

[Tiny SIMTを作ろう](https://karino2.github.io/2019/10/02/tinysimd.html)


## Build IP

最初にIPをビルドする必要があります。

- MIG
- JTAG-AXI
- MMCM

を生成します。

もともとは[shuntarot/arty-mig: Arty FPGA sample](https://github.com/shuntarot/arty-mig/)から作ってあるのでmakeの環境があれば以下で作れるはずですが、

```
cd ip
make build
```

自分はmakeを持っていないので、PowerShellから手動でビルドしました。以下のような感じ。

```
cd ip
mkdir output
C:\Xilinx\Vivado\2019.1\bin\vivado.bat -mode tcl
tcl% source arty.tcl
```


## Build

Arty-7 35T FPGA imageを以下のフォルダでビルドします。

```
cd syn
./compile.ps1
```

## Program

USBをartyボードにつなげて以下を実行します。
Need USB connected Arty board.

```
cd syn
./program.ps1
```

## イメージの説明

4コアのSIMTに、ROMとしてヒストグラムを求める物が入っています。
アセンブリとしては、[DDCA_exercise/asm/asm_files/simt_histo32.s](https://github.com/karino2/DDCA_exercise/blob/master/asm/asm_files/simt_histo32.s)になります。

まずプログラムがhaltまで行くとLEDが光り、DDRのアクセスがjtagに切り替わります。
そのあと

```
cd syn
C:\Xilinx\Vivado\2019.1\bin\vivado.bat -mode tcl -source jtag_setup.tcl
tcl% 
```

と実行するとjtagを使える状態になります。`mr 12`でアドレス12のワードを読み、`mw 4 123`でアドレス4に123を書き込みます。

push button1を押すとCPUだけリセットがかかり最初から実行します。

### ヒストグラムのプログラムの仕様

ヒストグラムはアドレス0x0000-0x0080の範囲に置かれているバイナリを1バイトずつ見て、0～255のどの値がいくつあるかを数えます。
結果は0x0100-0x0500までの範囲に置きます。
0の出現回数は0x0100、1の出現回数は0x0104、2の出現回数は0x0108、....と、各度数は4バイトとして保存してあります。

試し方としては、まず起動しjtagアクセスできるようになるまで待ち、jtagで0x0000-0x0080の範囲にデータを置き、
push button1を押してリセットを押し、最後にjtagで0x0100-0x0500のデータを読む、という形になります。

試すデータとして自分の手元の写真から作ったwrite_target.tclというファイルを作ったので、これを以下のように実行するとテスト用のデータを準備出来ます。

```
cd syn
C:\Xilinx\Vivado\2019.1\bin\vivado.bat -mode tcl -source jtag_setup.tcl
tcl% source write_target.tcl
```

このあとpush button1を押すとプログラムが走り、[DDCA_exercise/hist/expect.txt](https://github.com/karino2/DDCA_exercise/blob/master/hist/expect.txt)にあるような結果になるはずです。
100のあたりの度数(アドレスとしては656バイト目あたり)をmrで見ると比較出来ると思います。