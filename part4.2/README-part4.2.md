# ...existing code...

---

> ⚠️❗**WAŻNE! Po pobraniu lub sklonowaniu repozytorium na systemie Linux należy nadać uprawnienia wykonywalności skryptom i hookom.**
> 
> W katalogu projektu uruchom:
> 
> ```bash
> chmod +x config/includes.chroot/usr/local/bin/mojdebian-shell.sh
> chmod +x config/includes.chroot/usr/local/bin/update-issue.sh
> chmod +x config/hooks/normal/configure-locale.chroot
> chmod +x config/hooks/normal/enable-mojdebian-console.chroot
> chmod +x config/hooks/normal/enable-update-issue.chroot
> chmod +x config/hooks/normal/install-webui.chroot
> chmod +x config/hooks/normal/enable-mywebui.chroot
> ```
> 
> Bez tych uprawnień skrypty nie będą działać podczas budowy obrazu ISO!

# ...existing code...