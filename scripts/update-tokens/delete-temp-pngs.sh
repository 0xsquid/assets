echo "Asking for sudo permission to delete temp png files (check ./scripts/update-tokens/delete-temp-pngs.sh)"
# remove temp png files, which are needed to extract colors as webp is not supported by node canvas
sudo rm -rf "images/migration/png"