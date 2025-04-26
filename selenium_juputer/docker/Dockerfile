FROM jupyter/base-notebook:2023-06-05
USER root
RUN apt-get update && \
    apt-get install -yq tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Taipei /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && apt-get install -y gnupg2

COPY requirements.txt /
RUN pip3 install --no-cache-dir -r /requirements.txt
RUN jupyter contrib nbextension install 

# ===========================================================================
# JUPYTER NOTEBOOK EXTENSIONS
# ===========================================================================

# define the jupyter directories explicitly to make them user-independent
#ENV JUPYTER_CONFIG_DIR /jupyter/.jupyter
#ENV JUPYTER_DATA_DIR /jupyter/.local/share/jupyter
#ENV JUPYTER_RUNTIME_DIR /jupyter/.local/share/jupyter/runtime

#USER 0
# make sure the directories exist
#RUN mkdir -p $JUPYTER_CONFIG_DIR
#RUN mkdir -p $JUPYTER_DATA_DIR
#RUN mkdir -p $JUPYTER_RUNTIME_DIR

#WORKDIR /home
#RUN python3 -c "import matplotlib, scipy, numpy, pandas, sklearn, seaborn, yt, patsy, sympy, IPython, statsmodels"
# install google chrome


RUN apt -f install -y
RUN apt-get install -y wget
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt-get install ./google-chrome-stable_current_amd64.deb -y


#RUN apt-get install -y chromium    
# install chromedriver
# install chromedriver

# set display port to avoid crash
ENV DISPLAY=:99