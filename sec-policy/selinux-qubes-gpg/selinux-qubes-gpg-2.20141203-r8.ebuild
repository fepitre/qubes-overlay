# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit selinux-policy-2

BASEPOL='2.20141203-r8'
MODS="qubes-gpg"
POLICY_FILES="qubes-gpg.te qubes-gpg.if qubes-gpg.fc"

DESCRIPTION='SELinux policy for Qubes split GPG'
HOMEPAGE='https://github.com/2d1/qubes-policy'

KEYWORDS="~amd64"
LICENSE='GPL-3'
SLOT='0'

DEPEND="sec-policy/selinux-qubes-core"
RDEPEND="sec-policy/selinux-qubes-core"
