Name:           iputils
#BuildRequires:  docbook_3
#BuildRequires:  iso_ent
BuildRequires:  libopenssl-devel
#BuildRequires:  opensp
#BuildRequires:  perl-SGMLS
#BuildRequires:  sysfsutils-devel
BuildRequires:  libcap-devel
Summary:        IPv4 and IPv6 Networking Utilities
License:        BSD-3-Clause ; GPL-2.0+
Group:          Productivity/Networking/Other
Version:        s20121126
Release:        0
Url:            http://www.skbuff.net/iputils
Source:         http://www.skbuff.net/iputils/iputils-%{version}.tar.bz2
Source1001: 	iputils.manifest

%description
This package contains some small network tools for IPv4 and IPv6 like
rdisc, ping6, traceroute6, tracepath, and tracepath6.

%prep
%setup -q
cp %{SOURCE1001} .
mkdir linux
touch linux/autoconf.h

%build
make %{?_smp_mflags} KERNEL_INCLUDE=$PWD \
	CCOPT='%optflags -fno-strict-aliasing -fpie -D_GNU_SOURCE' \
	LDLIBS='-pie -lcap -lresolv' \
	CAPABILITIES=1

%install
mkdir -p $RPM_BUILD_ROOT/%_sbindir
mkdir -p $RPM_BUILD_ROOT/%_bindir
install arping		$RPM_BUILD_ROOT/%{_sbindir}
install clockdiff	$RPM_BUILD_ROOT/%{_sbindir}
install rdisc		$RPM_BUILD_ROOT/%{_sbindir}/in.rdisc
install tracepath	$RPM_BUILD_ROOT/%{_sbindir}
install tracepath6	$RPM_BUILD_ROOT/%{_sbindir}
install ping		$RPM_BUILD_ROOT/%{_bindir}
install ping6		$RPM_BUILD_ROOT/%{_bindir}
install ipg			$RPM_BUILD_ROOT/%{_bindir}

%files
%manifest %{name}.manifest
%defattr(-,root,root)
%{_sbindir}/arping
%{_sbindir}/clockdiff
%verify(not mode caps) %attr(4755,root,root) %{_bindir}/ping
%verify(not mode caps) %attr(4755,root,root) %{_bindir}/ping6
%{_bindir}/ipg
%{_sbindir}/tracepath
%{_sbindir}/tracepath6
%{_sbindir}/in.rdisc

%changelog
