# Estimator package images

The uploader recursively uploads image files in each package folder to Firebase
Storage and writes the package metadata and Storage paths to the
`estimator_packages` Firestore collection.

You do not need to create the collection or five documents manually. After the
upload script runs successfully, it creates or updates the documents with IDs
`basic`, `modern`, `deluxe`, `premium`, and `luxury`. It stores Storage paths
(`coverImagePath` and `imagePaths`), which the app resolves to download URLs.

For images uploaded manually, place each package folder (`Basic`, `Modern`,
`Deluxe`, `Premium`, `Luxury`) under `estimator_packages/`, `packages/`, or the
bucket root, with category folders such as `TV`, `Bed`, and `Sofa` inside.
When Firestore contains only one image for a package, the app discovers all
nested images in its Storage folder. The package card shows one image at a
time; use its arrows to cycle through the images.

Firebase Storage bucket: `gs://funica-9a16a.firebasestorage.app`
([open in Firebase Console](https://console.firebase.google.com/project/funica-9a16a/storage/funica-9a16a.firebasestorage.app/files)).

1. Download the shared Drive folder as a ZIP and extract it. The extracted
   directory must contain `Basic`, `Modern`, `Deluxe`, `Premium`, and `Luxury`
   folders.
2. Create a Firebase service-account key with permission to upload Storage
   objects and write Firestore documents. Keep the key outside the repository.
3. From PowerShell, set the local paths and run the uploader:

   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\secure\funica-admin.json'
   $env:ESTIMATOR_IMAGES_DIR = 'C:\path\to\extracted\FI Packages'
   npm.cmd --prefix scripts\estimator_images install
   npm.cmd --prefix scripts\estimator_images run upload
   ```

The uploader already defaults to this project ID and bucket. They can be
overridden with `GCLOUD_PROJECT` and `FIREBASE_STORAGE_BUCKET`.

The app must be allowed to read `estimator_packages` from Firestore. Firebase
Storage rules should allow authenticated reads under
`estimator_packages/{allPaths=**}` and deny client writes. Merge these rules
into the existing Firebase rules; do not replace unrelated rules.

For Firestore, merge this match into the existing Firestore rules:

```text
match /estimator_packages/{packageId} {
  allow read: if request.auth != null;
  allow write: if false;
}
```

For Firebase Storage, merge this match into the existing Storage rules:

```text
match /estimator_packages/{allPaths=**} {
  allow read: if request.auth != null;
  allow write: if false;
}
```
