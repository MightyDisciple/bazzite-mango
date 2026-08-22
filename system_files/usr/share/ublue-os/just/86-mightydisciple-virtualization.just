# Manage workstation virtualization, RTX 5080 passthrough and Looking Glass.
[group("MightyDisciple")]
workstation-virtualization ACTION="":
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

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

    if [[ -z "${action}" ]]; then
        selection=$(Choose \
            "Enable RTX 5080 passthrough" \
            "Disable RTX 5080 passthrough" \
            "Show RTX 5080 passthrough status" \
            "Enable Looking Glass KVMFR" \
            "Open Bazzite virtualization setup")

        case "${selection}" in
            "Enable RTX 5080 passthrough") action="rtx-on" ;;
            "Disable RTX 5080 passthrough") action="rtx-off" ;;
            "Show RTX 5080 passthrough status") action="status" ;;
            "Enable Looking Glass KVMFR") action="kvmfr" ;;
            "Open Bazzite virtualization setup") action="setup" ;;
        esac
    fi

    case "${action,,}" in
        rtx-on)
            verify_hardware
            # The Bazzite image initramfs already includes the VFIO drivers.
            # Keep this toggle limited to kernel arguments so bootc upgrades
            # remain possible without local rpm-ostree modifications.
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
        rtx-off)
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
        kvmfr)
            sudo /usr/libexec/bazzite-dx-kvmfr-setup
            ;;
        setup)
            ujust setup-virtualization
            ;;
        *)
            echo "Usage: ujust workstation-virtualization {rtx-on|rtx-off|status|kvmfr|setup}" >&2
            exit 2
            ;;
    esac
