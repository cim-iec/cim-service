FROM fedora:32

RUN dnf -y update

# Toolchain
RUN dnf -y install \
	gcc gcc-c++ clang \
	git \
	rpmdevtools rpm-build \
	make cmake pkgconfig \
	python3-pip

# Tools needed for developement
RUN dnf -y install \
	doxygen graphviz \
	gdb

# Dependencies
RUN dnf --refresh -y install \
	python3-devel \
	eigen3-devel \
	libxml2-devel \
	graphviz-devel \
	gsl-devel \
	spdlog-devel \
	fmt-devel \
	pybind11-devel

# Install some debuginfos
RUN dnf -y debuginfo-install \
	python3

# CIMpp and VILLAS are installed here
ENV LD_LIBRARY_PATH="/usr/local/lib64:${LD_LIBRARY_PATH}"

# Install CIMpp from source
RUN cd /tmp && \
	git clone --recursive https://github.com/CIM-IEC/libcimpp.git && \
	mkdir -p libcimpp/build && cd libcimpp/build && \
	cmake -DCMAKE_INSTALL_LIBDIR=/usr/local/lib64 -DUSE_CIM_VERSION=IEC61970_16v29a -DBUILD_SHARED_LIBS=ON -DBUILD_ARABICA_EXAMPLES=OFF .. && make -j$(nproc) install && \
	rm -rf /tmp/libcimpp

# Python dependencies
ADD requirements-dpsim.txt .
RUN pip3 install -r requirements-dpsim.txt

# Activate Jupyter extensions
RUN dnf -y --refresh install npm
RUN jupyter nbextension enable --py widgetsnbextension
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager

# Build DPsim from source
RUN mkdir /dpsim
RUN cd /dpsim && \
	git clone --recursive https://github.com/dpsim-simulator/dpsim.git && \
	mkdir -p dpsim/build && cd dpsim/build && \
	cmake  -DBUILD_EXAMPLES=OFF -DPYBIND=ON .. && \
	make -j$(nproc) dpsimpy

# CIMpy-Server
# Install libxml dependencies
RUN dnf -y install libxslt-devel libxslt && \
    pip install --no-cache-dir lxml>=3.5.0

RUN pip3 install --no-cache-dir pytest webtest
RUN pip3 install --no-cache-dir flake8

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY requirements.txt /usr/src/app/
RUN pip3 install --no-cache-dir -r requirements.txt

# COPY . /usr/src/app

# EXPOSE 8080

# ENTRYPOINT ["python3"]

# CMD ["-m", "openapi_server"]