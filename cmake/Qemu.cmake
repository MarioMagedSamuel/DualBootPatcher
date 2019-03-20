if(${MBP_BUILD_TARGET} STREQUAL device)
    set(MBP_ENABLE_QEMU FALSE CACHE BOOL "Enable running tests in QEMU")

    if(MBP_ENABLE_QEMU)
        set(qemu_arch)
        set(qemu_extra_args)
        set(qemu_console)
        set(qemu_9p_device)

        if("${ANDROID_ABI}" STREQUAL armeabi-v7a)
            set(qemu_arch arm)
            list(APPEND qemu_extra_args -machine virt -cpu cortex-a15)
            set(qemu_console ttyAMA0)
            set(qemu_9p_device virtio-9p-device)
        elseif("${ANDROID_ABI}" STREQUAL arm64-v8a)
            set(qemu_arch aarch64)
            list(APPEND qemu_extra_args -machine virt -cpu cortex-a57)
            set(qemu_console ttyAMA0)
            set(qemu_9p_device virtio-9p-pci)
        elseif("${ANDROID_ABI}" STREQUAL x86)
            set(qemu_arch i386)
            list(APPEND qemu_extra_args -cpu Nehalem)
            set(qemu_console ttyS0)
            set(qemu_9p_device virtio-9p-pci)
        elseif("${ANDROID_ABI}" STREQUAL x86_64)
            set(qemu_arch x86_64)
            list(APPEND qemu_extra_args -cpu Nehalem)
            set(qemu_console ttyS0)
            set(qemu_9p_device virtio-9p-pci)
        else()
            message(FATAL_ERROR "Unknown ABI: ${ANDROID_ABI}")
        endif()

        set(qemu_binary "qemu-system-${qemu_arch}")

        find_program(
            "QEMU_SYSTEM"
            "${qemu_binary}"
            DOC "Path to ${qemu_binary} binary"
        )
        if(NOT QEMU_SYSTEM)
            message(FATAL_ERROR "MBP_ENABLE_QEMU is enabled, but ${qemu_binary} was not found")
        endif()

        set(qemu_command
            "${QEMU_SYSTEM}"
            -kernel "${TEST_RUNNER_IMAGE_DIR}/kernel.img"
            -initrd "${TEST_RUNNER_IMAGE_DIR}/ramdisk.img"
            -smp 4
            -m 512
            -nographic
            -no-reboot
            -fsdev "local,id=workspace,path=${CMAKE_BINARY_DIR},security_model=none"
            -device "${qemu_9p_device},fsdev=workspace,mount_tag=workspace"
            ${qemu_extra_args}
        )

        set(qemu_kernel_args "console=${qemu_console} qemu-mount=workspace")

        add_custom_target(
            qemu-shell
            ${qemu_command}
            -append "${qemu_kernel_args}"
            VERBATIM
            USES_TERMINAL
        )

        add_custom_command(
            OUTPUT "${CMAKE_BINARY_DIR}/cmake/qemu_run_tests.sh"
            MAIN_DEPENDENCY "${CMAKE_SOURCE_DIR}/cmake/qemu_run_tests.sh"
            COMMAND ${CMAKE_COMMAND} -E copy
                    "${CMAKE_SOURCE_DIR}/cmake/qemu_run_tests.sh"
                    "${CMAKE_BINARY_DIR}/cmake/qemu_run_tests.sh"
        )

        add_custom_target(
            qemu-tests
            ${qemu_command}
            -append "${qemu_kernel_args} quiet post-init=/mnt/workspace/cmake/qemu_run_tests.sh"
            DEPENDS "${CMAKE_BINARY_DIR}/cmake/qemu_run_tests.sh"
            VERBATIM
            USES_TERMINAL
        )
    endif()
endif()
