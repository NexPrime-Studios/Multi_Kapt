## --- REGRAS DO PROJETO (Multi_Kapt) ---

# Preservar as classes de modelos (Essencial para o Supabase/PostgreSQL)
# Isso evita que o R8 mude o nome dos campos que devem bater com o Banco de Dados
-keep class com.nexprimestudios.multikapt.models.** { *; }

# Preservar atributos necessários para serialização de JSON e Reflection
-keepattributes Signature,Exceptions,*Annotation*

## --- REGRAS GOOGLE PLAY & IN-APP UPDATE ---

# Força o R8 a manter as classes de Split Install (exigido pelo Flutter App Bundle)
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.common.** { *; }

# Mantém as classes de tarefas (OnSuccessListener, etc) usadas pelo InAppUpdate
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Mantém as classes do Google Play Core em geral (evita erros residuais)
-keep class com.google.android.play.core.** { *; }

# IGNORA AVISOS: Essencial para não travar o build se o R8 encontrar referências 
# a partes da biblioteca que você não está usando explicitamente.
-dontwarn com.google.android.play.core.**

## --- REGRAS PARA PLUGINS E FLUTTER INTERNO ---

# Regras para bibliotecas que usam Gson ou serialização
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# Evitar que o R8 remova métodos essenciais do motor do Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }

# Se você usar o OkHttp (muito comum em plugins de rede)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**