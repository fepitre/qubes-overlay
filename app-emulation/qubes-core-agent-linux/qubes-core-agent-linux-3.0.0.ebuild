# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-agent-linux.git'

PYTHON_COMPAT=( python2_7 )

inherit eutils git-2 python-r1 user

DESCRIPTION='Qubes RPC agent for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

IUSE="selinux"
KEYWORDS=""
LICENSE='GPL-2'

if ( [ "${PV%%.*}" == 2 ] || [ "${PR}" == 'r200' ] ); then {

	EGIT_BRANCH='release2'
	SLOT=2
	DEPEND="!${CATEGORY}/${PN}:3"

	}; else {

	EGIT_BRANCH='master'
	SLOT=3
	DEPEND="!${CATEGORY}/${PN}:2"
};
fi

COMMON_DEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/qubes-linux-utils:${SLOT}
	app-emulation/xen-tools"

DEPEND="${COMMON_DEPEND}
	${DEPEND}
	app-crypt/gnupg"

# util-linux for logger
#
RDEPEND="${COMMON_DEPEND}
	selinux? ( sec-policy/selinux-qubes )
	sys-apps/util-linux"

src_prepare() {

	if [[ "${PV}" < '9999' ]]; then {

		readonly version="v${PV}"
		git checkout "${version}" 2>/dev/null

	}; else {

		readonly version="$(git tag --points-at HEAD | head -n 1)"
	};
	fi

	gpg --import "${FILESDIR}/qubes-developers-keys.asc" 2>/dev/null
	git verify-tag "${version}" || die 'Signature verification failed!'

	if ( [ ${SLOT} == 2 ] && [ "${PV}" != '9999' ] ); then {

		epatch "${FILESDIR}/${PN}-2.1.55_misc-Makefile-remove-Werror.patch"
		epatch "${FILESDIR}/${PN}-2.1.55_qrexec-Makefile-remove-Werror.patch"
		epatch "${FILESDIR}/${PN}-2.1.55_qrexec-agent-rc.d-to-openrc.patch"
		epatch "${FILESDIR}/${PN}-2.1.55_qubes-rpc-Makefile-remove-Werror.patch"
	};
	fi

	epatch_user
}

pkg_setup() {

	# for regular users to read and place/remove files
	enewgroup 'qubes-transfer'
	# 'user' is used in template VMs and qrexec-agent operates
	# within the associated $HOME when copying files.
	enewuser 'user' -1 -1 '/home/user' 'qubes-transfer'

	chgrp qubes-transfer -- /home/user /home/user/QubesIncoming
}

src_compile() {

	emake all
}

src_install() {

	cd "${S}/qrexec"

	emake DESTDIR="${D}" install

	cd "${S}"

	emake DESTDIR="${D}" install-sysvinit

	insinto '/etc/qubes-rpc'
	doins qubes-rpc/qubes.{Filecopy,OpenInVM}

	exeinto '/usr/bin'
	exeopts '-m0755'
	doexe qubes-rpc/qvm-{copy-to-vm,move-to-vm,mru-entry,open-in-dvm,open-in-vm,run}

	exeinto '/usr/lib/qubes'
	exeopts '-m0711'
	doexe qubes-rpc/{qfile-agent,qfile-unpacker,tar2qfile}

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes.conf"

}

pkg_postinst() {

	echo
	ewarn "qrexec-agent must be running before qrexec_timeout"
	ewarn "(default value = 60 seconds) is reached."
	ewarn
	ewarn "qrexec-agent requires the 'u2mfn' kernel module."
	ewarn "Either emerge qubes-kernel-module or patch the kernel"
	ewarn "manually for a static build."
	ewarn
	ewarn "Additionally, you must set 'qrexec_installed' to True"
	ewarn "for your domU to use Qubes RPC."
	echo
	einfo "Inter-VM functions are invoked through qvm-* utils."
	echo
	einfo "File copying is performed inside the 'user' user's"
	einfo "\$HOME. Look for files under /home/user/QubesIncoming".
	echo
	einfo "Add regular users to the 'qubes-transfer' group to read"
	einfo "and manipulate files there."
	echo
}
