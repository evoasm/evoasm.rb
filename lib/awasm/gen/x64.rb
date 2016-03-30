module Awasm::Gen
  module X64
    MNEM_BLACKLIST = %w()

    # RFLAGS either not used at all
    # or not read by any non-system instruction
    IGNORED_RFLAGS = %i(RF VIF AC VM NT TF DF IF AF)

    # Exception flag/mask bits. Mostly meant to be checked
    # by the user, which we are not doing at the moment
    IGNORED_MXCSR = %i(PE UE OE ME ZE DE IE PM UM OM ZM DM IM MM)
    REGISTERS = {
      ip: %i(IP),
      rflags: %i(OF SF ZF PF CF),
      mxcsr: %i(FZ RC DAZ),
      gp: %i(A C D B SP BP SI DI 8 9 10 11 12 13 14 15),
      mm: %i(MM0 MM1 MM2 MM3 MM4 MM5 MM6 MM7),
      xmm: %i(XMM0 XMM1 XMM2 XMM3 XMM4 XMM5 XMM6 XMM7 XMM8 XMM9 XMM10 XMM11 XMM12 XMM13 XMM14 XMM15),
      zmm: %i(ZMM16 ZMM17 ZMM18 ZMM19 ZMM20 ZMM21 ZMM22 ZMM23 ZMM24 ZMM25 ZMM26 ZMM27 ZMM28 ZMM29 ZMM30 ZMM31)
    }

    REGISTER_NAMES = REGISTERS.values.flatten

    CPUID = {
      [0x1, nil] => {
        d: %i(
          fpu
          vme
          de
          pse
          tsc
          msr
          pae
          mce
          cx8
          apic
          reserved
          sep
          mtrr
          pge
          mca
          cmov
          pat
          pse36
          psn
          clfsh
          reserved
          ds
          acpi
          mmx
          fxsr
          sse
          sse2
          ss
          htt
          tm
          ia64
          pbe),
        c: %i(
          sse3
          pclmulqdq
          dtes64
          monitor
          ds_cpl
          vmx
          smx
          est
          tm2
          ssse3
          cnxt_id
          sdbg
          fma
          cx16
          xtpr
          pdcm
          reserved
          pcid
          dca
          sse4_1
          sse4_2
          x2apic
          movbe
          popcnt
          tsc_deadline
          aes
          xsave
          osxsave
          avx
          f16c
          rdrnd
          hypervisor
        )
      },
      [0x7, 0x0] => {
        b: %i(
          fsgsbase
          IA32_TSC_ADJUST
          sgx
          bmi1
          hle
          avx2
          reserved
          smep
          bmi2
          erms
          invpcid
          rtm
          pqm
          FPU_CS_DS_DEPRECATED
          mpx
          pqe
          avx512f
          avx512dq
          rdseed
          adx
          smap
          avx512ifma
          pcommit
          clflushopt
          clwb
          avx512pf
          avx512er
          avx512cd
          sha
          avx512bw
          avx512vl
        ),

        c: %i(
          prefetchwt1
          avx512vbmi
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
          reserved
        )
      },

      [0x80000001, nil] => {
        d: %i(
          fpu
          vme
          de
          pse
          tsc
          msr
          pae
          mce
          cx8
          apic
          reserved
          syscall
          mtrr
          pge
          mca
          cmov
          pat
          pse36
          reserved
          mp
          nx
          reserved
          mmxext
          mmx
          fxsr
          fxsr_opt
          pdpe1gb
          rdtscp
          reserved
          lm
          3dnowext
          3dnow
        ),

        c: %i(
          lahf_lm
          cmp_legacy
          svm
          extapic
          cr8_legacy
          abm
          sse4a
          misalignsse
          3dnowprefetch
          osvw
          ibs
          xop
          skinit
          wdt
          reserved
          lwp
          fma4
          tce
          nodeid_msr
          reserved
          tbm
          topoext
          perfctr_core
          perfctr_nb
          reserved
          dbx
          perftsc
          pcx_l2i
          reserved
          reserved
          reserved
        )
      }
    }
  end
end
