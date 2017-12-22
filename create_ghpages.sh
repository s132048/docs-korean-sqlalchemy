# current git branch must be 'docs-korean'
git add . -A
git commit -m "automatic commit"
git push origin docs-korean

git checkout -B gh-pages
git rebase docs-korean

touch .nojekyll
echo '!doc/build/' >> .gitignore
echo '!/doc/build/output/' .. .gitignore

cd doc
make html
