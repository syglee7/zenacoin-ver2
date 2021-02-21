#!/usr/bin/env bash
# Copyright (c) 2016-2020 The Zenacoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C
TOPDIR=${TOPDIR:-$(git rev-parse --show-toplevel)}
BUILDDIR=${BUILDDIR:-$TOPDIR}

BINDIR=${BINDIR:-$BUILDDIR/src}
MANDIR=${MANDIR:-$TOPDIR/doc/man}

ZENACOIND=${ZENACOIND:-$BINDIR/zenacoind}
ZENACOINCLI=${ZENACOINCLI:-$BINDIR/zenacoin-cli}
ZENACOINTX=${ZENACOINTX:-$BINDIR/zenacoin-tx}
WALLET_TOOL=${WALLET_TOOL:-$BINDIR/zenacoin-wallet}
ZENACOINUTIL=${ZENACOINQT:-$BINDIR/zenacoin-util}
ZENACOINQT=${ZENACOINQT:-$BINDIR/qt/zenacoin-qt}

[ ! -x $ZENACOIND ] && echo "$ZENACOIND not found or not executable." && exit 1

# Don't allow man pages to be generated for binaries built from a dirty tree
DIRTY=""
for cmd in $ZENACOIND $ZENACOINCLI $ZENACOINTX $WALLET_TOOL $ZENACOINUTIL $ZENACOINQT; do
  VERSION_OUTPUT=$($cmd --version)
  if [[ $VERSION_OUTPUT == *"dirty"* ]]; then
    DIRTY="${DIRTY}${cmd}\n"
  fi
done
if [ -n "$DIRTY" ]
then
  echo -e "WARNING: the following binaries were built from a dirty tree:\n"
  echo -e $DIRTY
  echo "man pages generated from dirty binaries should NOT be committed."
  echo "To properly generate man pages, please commit your changes to the above binaries, rebuild them, then run this script again."
fi

# The autodetected version git tag can screw up manpage output a little bit
read -r -a ZNCVER <<< "$($ZENACOINCLI --version | head -n1 | awk -F'[ -]' '{ print $6, $7 }')"

# Create a footer file with copyright content.
# This gets autodetected fine for zenacoind if --version-string is not set,
# but has different outcomes for zenacoin-qt and zenacoin-cli.
echo "[COPYRIGHT]" > footer.h2m
$ZENACOIND --version | sed -n '1!p' >> footer.h2m

for cmd in $ZENACOIND $ZENACOINCLI $ZENACOINTX $WALLET_TOOL $ZENACOINUTIL $ZENACOINQT; do
  cmdname="${cmd##*/}"
  help2man -N --version-string=${ZNCVER[0]} --include=footer.h2m -o ${MANDIR}/${cmdname}.1 ${cmd}
  sed -i "s/\\\-${ZNCVER[1]}//g" ${MANDIR}/${cmdname}.1
done

rm -f footer.h2m
