source .venv/bin/activate
cd ./test_en
echo "Open in browser  <ip>:8006/test_page_en.html"
python -m http.server 8006
cd ..
