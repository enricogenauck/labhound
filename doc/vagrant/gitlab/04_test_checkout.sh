echo 'Setup working directory for test project'
git clone git@localhost:root/labhound-test.git
cd labhound-test/
git checkout -b master
git commit -am "first master commit"
git push origin master
git checkout -b feature
touch rubyscript.rb
git add rubyscript.rb
git commit -m "initial commit"
git push origin feature
