import langcodes

language_names = {
    lang_code: langcodes.Language.get(lang_code).display_name('vi')
    for lang_code in ['vi', 'en', 'fr', 'de', 'es', 'it', 'ja', 'ko', 'zh', 'ru']
}

print(language_names)