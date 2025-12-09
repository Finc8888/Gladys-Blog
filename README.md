# 📝 GladysAI-Blog
## Link to local site
```bash
192.168.100.5   gladys-blog.local.net
```
## Theme
```bash
cd blog/gladys
git submodule add git@github.com:MeiK2333/github-style.git themes/github-style
```
### Add post
```bash
hugo new post/title_of_the_post.md
```

### Deploy
#### Local in root of project
```bash
docker compose run --rm blog-build
./deploy.sh
```
#### On server:
```bash
cd ~/Gladys-Blog
./reboot.sh
```
