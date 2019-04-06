# 具体cuda的版本需根据当前host主机的NVIDIA驱动版本对应
from pytorch/pytorch:1.0.1-cuda10.0-cudnn7-devel
WORKDIR /project
# 配置国内源
run pip install pip -U
run pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
add requirements.txt .
# 建议使用自己本地最快的source文件
copy sources.list /etc/apt/sources.list
run pip install -r requirements.txt
# 如果没有，那么就需要单独去下
# run curl --create-dirs -o /root/.torch/models/alexnet-owt-4df8aa71.pth https://download.pytorch.org/models/alexnet-owt-4df8aa71.pth
run mkdir -p /root/.torch/models
copy alexnet-owt-4df8aa71.pth /root/.torch/models/
# 安装faiss相关依赖以及安装faiss
workdir /opt
RUN apt-get update -y
RUN apt-get install -y libopenblas-dev swig git wget
RUN pip install matplotlib
RUN pip install python-config
# 默认情况下应该在clone当前的项目的时候faiss已经在项目中了
run wget -c https://github.com/facebookresearch/faiss/archive/v1.4.0.zip
run apt-get install -y unzip
run unzip v1.4.0.zip
WORKDIR /opt/faiss-1.4.0

ENV BLASLDFLAGS /usr/lib/libopenblas.so.0

ENV PATH=/opt/conda/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/conda/lib:$LD_LIBRARY_PATH

# 安装CPU版
RUN ./configure --with-python-config=python3.6m-config

RUN make -j $(nproc) && \
    make py

RUN cd gpu && \
    make -j $(nproc)

RUN cd python && \
    make all && \
    make gpu && \
    make install

ENV PYTHONPATH $PYTHONPATH:/opt/faiss-1.4.0
RUN cd tutorial/python && \
    python 4-GPU.py