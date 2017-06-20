FROM alpine:3.6

MAINTAINER mirwing <mirwing@mirwing.com>

ENV LANG=C.UTF-8 \
	GLIBC_VERSION=2.25-r0

RUN set -ex \
	&& apk upgrade --update \
	&& apk add --update curl ca-certificates tar unzip 

RUN	for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done \
	&& apk add --allow-untrusted /tmp/*.apk \
	&& rm -v /tmp/*.apk \
	&& ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) \
	&& echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh \
	&& /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

ENV JAVA_VERSION_MAJOR=8 \
	JAVA_VERSION_MINOR=131 \
	JAVA_VERSION_BUILD=11 \
	JAVA_VERSION_PATH=d54c1d3a095b4ff2b6607d096fa80163 \
	JAVA_PACKAGE=jdk \
	JAVA_JCE=standard

RUN mkdir /opt \
	&& curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
		http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_VERSION_PATH}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
    && gunzip /tmp/java.tar.gz \
    && tar -C /opt -xf /tmp/java.tar \
    && ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk \
    && find /opt/jdk/ -maxdepth 1 -mindepth 1 | grep -v jre | xargs rm -rf \
    && cd /opt/jdk \
	&& ln -s ./jre/bin ./bin \
	&& if [ "${JAVA_JCE}" == "unlimited" ]; then echo "Installing Unlimited JCE policy" \
		&& curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
			http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip \
		&& cd /tmp \
		&& unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
		&& cp -v /tmp/UnlimitedJCEPolicyJDK8/*.jar /opt/jdk/jre/lib/security/ \
		&& sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ $JAVA_HOME/jre/lib/security/java.security; \
		fi \
	&& rm -rf /tmp/* \
	&& echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

RUN apk del curl unzip tar glibc-i18n \
	&& rm -rf /var/cache/apk/*

ENV JAVA_HOME=/opt/jdk
ENV PATH=${PATH}:${JAVA_HOME}/bin

CMD ["/bin/sh"]
