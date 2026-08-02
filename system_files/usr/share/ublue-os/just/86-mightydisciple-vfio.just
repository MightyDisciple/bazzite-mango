# Toggle the dedicated RTX 5080 between the Bazzite host and VFIO passthrough.
rtx5080-vfio ACTION="status":
    #!/usr/bin/bash
    set -euo pipefail

    readonly gpu_pci="0000:01:00.0"
    readonly audio_pci="0000:01:00.1"
    readonly gpu_id="10de:2c02"
    readonly audio_id="10de:22e9"
    readonly vfio_ids="vfio_pci.ids=${gpu_id},${audio_id}"
    action="{{ ACTION }}"

    if [[ "${EUID}" -eq 0 ]]; then
        echo "Run this command as your normal user, without sudo." >&2
        exit 1
    fi

    verify_hardware() {
        local gpu_vendor gpu_device audio_vendor audio_device

        gpu_vendor="$(<"/sys/bus/pci/devices/${gpu_pci}/vendor")"
        gpu_device="$(<"/sys/bus/pci/devices/${gpu_pci}/device")"
        audio_vendor="$(<"/sys/bus/pci/devices/${audio_pci}/vendor")"
        audio_device="$(<"/sys/bus/pci/devices/${audio_pci}/device")"

        [[ "${gpu_vendor#0x}:${gpu_device#0x}" == "${gpu_id}" ]] || {
            echo "Unexpected device at ${gpu_pci}; refusing to change boot arguments." >&2
            exit 1
        }
        [[ "${audio_vendor#0x}:${audio_device#0x}" == "${audio_id}" ]] || {
            echo "Unexpected device at ${audio_pci}; refusing to change boot arguments." >&2
            exit 1
        }
    }

    case "${action,,}" in
        on)
            verify_hardware
            rpm-ostree initramfs --enable
            rpm-ostree kargs \
                --append-if-missing="amd_iommu=on" \
                --append-if-missing="iommu=pt" \
                --append-if-missing="rd.driver.pre=vfio-pci" \
                --append-if-missing="vfio_pci.disable_vga=1" \
                --append-if-missing="kvm.ignore_msrs=1" \
                --append-if-missing="kvm.report_ignored_msrs=0" \
                --append-if-missing="${vfio_ids}"
            echo "RTX 5080 passthrough is staged. Reboot to activate it."
            ;;
        off)
            rpm-ostree kargs --delete-if-present="${vfio_ids}"
            echo "RTX 5080 host binding is staged. Reboot to return it to Bazzite."
            ;;
        status)
            if rpm-ostree kargs | grep -qwF "${vfio_ids}"; then
                echo "Configured for VFIO passthrough after the applicable reboot."
            else
                echo "Configured for use by the Bazzite host after the applicable reboot."
            fi
            echo
            lspci -nnk -s 01:00.0
            lspci -nnk -s 01:00.1
            ;;
        *)
            echo "Usage: ujust rtx5080-vfio {on|off|status}" >&2
            exit 2
            ;;
    esac
