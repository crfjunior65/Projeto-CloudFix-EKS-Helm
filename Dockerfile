# Usando a imagem oficial do Nginx baseada em Alpine
FROM nginx:alpine

# Definindo o diretório de trabalho
WORKDIR /usr/share/nginx/html

# Remove arquivos padrão do Nginx
#  RUN rm -rf ./*

# Copia os arquivos da aplicação cloudfix (HTML, JS, CSS, etc.) para dentro do container
#  COPY ./cloudfix/ /usr/share/nginx/html/

# (Opcional) Copiar configuração customizada do nginx
# COPY ./nginx.conf /etc/nginx/nginx.conf

# Expõe a porta 80 do container
EXPOSE 80

# Comando padrão que o Nginx já executa
CMD ["nginx", "-g", "daemon off;"]
