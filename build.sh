#docker build -t brainlife/fsl .

tag=0.5
docker build -t brainlife/trekker . && \
    docker tag brainlife/trekker brainlife/trekker:$tag && \
    docker push brainlife/trekker:$tag
