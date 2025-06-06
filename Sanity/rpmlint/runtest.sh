#!/bin/bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Description: Test for BZ#1932783 (Rebase librelp to latest upstream version)
#   Author: Attila Lakatos <alakatos@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2021 Red Hat, Inc.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || :
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="librdkafka"

rlJournalStart && {
    rlPhaseStartSetup
        if [ ! -f /run/ostree-booted ]; then
            rlLog "Package mode detected (classic boot), installing EPEL"
            if rlIsRHELLike '>=10'; then
                rlRun "dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm" 0 "Install EPEL"
            else
                rlRun "dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm" 0 "Install EPEL"
            fi
            rlRun "dnf config-manager --set-enable epel" 0 "Enable EPEL"
            rlRun "dnf install -y rpmlint" 0 "Install rpmlint"
            rlRun "dnf config-manager --set-disable epel" 0 "Disable EPEL"
        else
            rlLog "Image mode detected, skipping EPEL installation"
        fi
        rlRun "rlImport --all" 0 "Import libraries" || rlDie "cannot continue"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        CleanupRegister "rlRun 'rm -r $TmpDir' 0 'Removing tmp directory'"
        CleanupRegister 'rlRun "popd"'
        rlRun "pushd $TmpDir"
    rlPhaseEnd


    rlPhaseStartTest "Ensure system crypto policies are used by default"
        rlRun -s "rpmlint --info $PACKAGE" 0-64 "Check for common rpm problems"
        rlAssertNotGrep "crypto-policy-non-compliance-gnutls" $rlRun_LOG
        rlAssertNotGrep "crypto-policy-non-compliance-openssl" $rlRun_LOG
        rm -f $rlRun_LOG
    rlPhaseEnd;

    rlPhaseStartCleanup
        CleanupDo
    rlPhaseEnd

    rlJournalPrintText
rlJournalEnd; }
