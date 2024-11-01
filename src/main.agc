rem Digikoo
rem
rem (c) Patrick Premartin / Olf Software / Gamolf 2012

rem version 1.0 - juillet 2012

rem version 1.1
rem		août 2012:
rem     - correction typographique sur le bouton en français du training
rem     - mise en place de la version anglaise du jeu (bouton drapeau sur page d'accueil et traduction de tous les textes)
rem     - changement du texte des crédits
rem     - l'exécution sur tablette pourra se faire dans les 4 orientations, à condition que le jeu rentre intégralement au moins dans un sens
rem     - les écrans avec juste un bouton de sortie sont désomais entièrement clicables pour sortir
rem     - modification de l'écran de fin de partie : la saisie se fait directement dessus plutôt que de passer par un champ de saisie séparé
rem     - diminution du nombre des meilleurs scores (passage de 15 à 12) car l'affichage débordait sur le bas de l'écran
rem     - limitation des pseudos à 20 caractères (pour les afficher sans tout casser sur le tableau des scores)
rem		16/12/2015, pprem: 
rem		- conversion de AGK1 à AGK2
rem		- suppression du choix de la langue par l'utilisateur
rem		- prise en compte de la langue du système au démarrage de l'application

rem chargement des paramètres de l'application
gosub _param_load

rem definition du format de l'affichage
largeur = 756
hauteur = 924
SetVirtualResolution(largeur,hauteur)
SetResolutionMode(1)
if (((largeur < getDeviceWidth()) and (hauteur < getDeviceHeight())) or ((hauteur < getDeviceWidth()) and (largeur < getDeviceHeight())))
    // l'écran physique est plus grand que l'écran du jeu, celui-ci peut donc fonctionner dans tous les sens
    SetOrientationAllowed(1,1,1,1)
else
    // l'écran physique est plus petit que celui du jeu, on ne peut donc fonctionner qu'en "portrait"
    SetOrientationAllowed(1,1,0,0)
endif
sync()

rem chargement du titre du jeu et affichage en splash screen
imgLogo = loadImage("digikoo-logo-699x152.png")
titreSprite = charge_menu(499,imgLogo,0,0)
setSpriteY(titreSprite,(getVirtualHeight()-getSpriteHeight(titreSprite))/2)
montrer_sprite(titreSprite)
sync()

rem Initialisation des paramètres du jeu
nb_cases_maxi as integer = 9
nb_cases_mini as integer = 2
nb_cases as integer = 0
gagne as integer = 0
perdu as integer = 0
niveau as integer = 0

rem définition de la liste des textes pour les écrans en affichant
dim textes[50] as integer

rem Définition d'une case du jeu
type cellule
    rem valeur placee sur la cellule
    valeur as integer
    rem cellule fixee ou deplacable => 0 = pas fixee, 1 = fixee
    fixe as integer
endtype

rem Définition de la grille du jeu dans sa taille maximale
dim grille[nb_cases_maxi*nb_cases_maxi] as cellule

rem Définition d'un chiffre
type chiffre
    rem id de l'image du chiffre en jaune => en attente d'être utilisé
    jaune as integer
    rem id de l'image du chiffre en vert => sur la grille, correctement placé
    vert as integer
    rem id de l'image du chiffre en rouge => sur la grille, mal placé
    rouge as integer
    rem id de l'image du chiffre en noir => sur la grille, bloqués
    noir as integer
endtype

rem Définition de la liste des chiffres
dim chiffres[9] as chiffre

rem Définition d'un jeton (chiffre à placer sur la grille)
type sprite
    rem indique s'il correspond au 1, 2, 3, 4, 5, 6, 7, 8 ou 9
    valeur as integer
endtype

rem Définition de la liste de tous les jetons possibles
dim sprites[nb_cases_maxi] as sprite

rem Définition de la liste des numéros disponibles pour les répartir dans la grille de jeu
dim numeros[nb_cases_maxi] as integer

rem Chargement des images
rem => image d'une case du jeu
idImageCase = loadImage("case.png")
idImageCaseAnnulee = loadImage("caseannulee.png")
rem => images des chiffres des jetons dans leurs différentes couleurs
for i = 1 to 9
    chiffres[i].jaune = loadImage(str(i)+"-jaune.png")
    chiffres[i].vert = loadImage(str(i)+"-vert.png")
    chiffres[i].rouge = loadImage(str(i)+"-rouge.png")
    chiffres[i].noir = loadImage(str(i)+"-noir.png")
next i

rem Chargement des bruitages et musiques
rem (c) GSP 500 Noises
idSonVictoire = loadSound("16APLSSM.WAV")
idSonDefaite = loadSound("16CRDBOO.WAV")
rem GinnyCulp.com
idMusiqueAmbiance = loadMusic("SmoothElements.mp3")

if (music_onoff = 1) then playMusic(idMusiqueAmbiance)

rem Création des sprites du jeu
for i = 1 to nb_cases_maxi
    for j = 1 to nb_cases_maxi
        rem sprites utilisés pour la grille de jeu (de 100+1 à 100+nb_cases_maxi*nb_cases_maxi)
        idSprite = 100+i+j*nb_cases_maxi-nb_cases_maxi
        createSprite(idSprite,idImageCase)
        masquer_sprite(idSprite)
    next j
    rem sprites utilisés pour les choix de chiffres (de 1 à nb_cases_maxi)
    createSprite(i,idImageCase)
    masquer_sprite(i)
next i

rem Chargement d'un second sprite avec le logo pour l'afficher 2 fois dans l'écran de copyright
setSpriteY(titreSprite,0)
masquer_sprite(titreSprite)
titreSprite2 = 500
createSprite(titreSprite2,getSpriteImageID(titreSprite))
masquer_sprite(titreSprite2)

rem chargement des menus de l'écran d'accueil
rem les boutons de menu et images de chiffres font 82 pixels de haut
rem on met un espacement proportionnel entre eux sur la zone d'affichage en dessous du titre
nb_options = 5
espace_avant = (getVirtualHeight() - getSpriteHeight(titreSprite) - 82 * nb_options) / (nb_options+1)
gosub charger_images
menuTrainingSprite = charge_menu(501,imgTraining,titreSprite,espace_avant)
menuReprendrePartie = charge_menu(498,imgRestart,menuTrainingSprite,espace_avant)
menuJouerSprite = charge_menu(502,imgPlay,menuTrainingSprite,espace_avant)
menuScoresSprite = charge_menu(503,imgScore,menuJouerSprite,espace_avant)
menuOptionsSprite = charge_menu(504,imgOptions,menuScoresSprite,espace_avant)
menuCreditsSprite = charge_menu(505,imgCredits,menuOptionsSprite,espace_avant)

rem chargement des menus de l'écran d'options
nb_options = 3
espace_avant = (getVirtualHeight() - getSpriteHeight(titreSprite) - 82 * nb_options) / (nb_options+1)
menuMusicSprite = charge_menu(506,imgMusicOff,titreSprite,espace_avant)
dim idImageMusic[2] as integer
idImageMusic[1] = imgMusicOff
idImageMusic[2] = imgMusicOn
menuSoundFXSprite = charge_menu(507,imgSoundOff,menuMusicSprite,espace_avant)
dim idImageSon[2]
idImageSon[1] = imgSoundOff
idImageSon[2] = imgSoundOn
menuORetourSprite = charge_menu(508,imgBack,menuSoundFXSprite,espace_avant)

rem chargement des menus de l'écran de choix du nombre de cases pour le training
nb_options = 8
espace_avant = (getVirtualHeight() - getSpriteHeight(titreSprite) - 82 * nb_options) / (nb_options+1)
menuT3 = charge_menu(509,chiffres[3].noir,titreSprite,espace_avant)
menuT4 = charge_menu(510,chiffres[4].noir,menuT3,espace_avant)
menuT5 = charge_menu(511,chiffres[5].noir,menuT4,espace_avant)
menuT6 = charge_menu(512,chiffres[6].noir,menuT5,espace_avant)
menuT7 = charge_menu(513,chiffres[7].noir,menuT6,espace_avant)
menuT8 = charge_menu(514,chiffres[8].noir,menuT7,espace_avant)
menuT9 = charge_menu(515,chiffres[9].noir,menuT8,espace_avant)
menuTRetourSprite = charge_menu(516,imgBack,menuT9,espace_avant)

rem chargement des logos de la page des crédits du jeu
idImgGAMOLF = loadImage("gamolf-150x150.png")
idSprGAMOLF = 517
createSprite(idSprGAMOLF,idImgGAMOLF)
masquer_sprite(idSprGAMOLF)
idImgAGK = loadImage("Made-With-AGK-White-128px.png")
idSprAGK = 518
createSprite(idSprAGK,idImgAGK)
masquer_sprite(idSprAGK)

rem chargement des boutons affichés sur l'écran de jeu
idMnuJeuPause = 519
createSprite(idMnuJeuPause,imgPause)
masquer_sprite(idMnuJeuPause)
idMnuJeuOptions = 520
createSprite(idMnuJeuOptions,getSpriteImageID(menuOptionsSprite))
masquer_sprite(idMnuJeuOptions)
idMnuJeuStop = 521
createSprite(idMnuJeuStop,getSpriteImageID(menuTRetourSprite))
masquer_sprite(idMnuJeuStop)
idMnuSuite = 522
createSprite(idMnuSuite,imgNext)
masquer_sprite(idMnuSuite)

rem initialisation des paramètres utilisés pour le tableau des scores
type tscore
    pseudo$ as string
    niveau as integer
    transmis$ as string
endtype
nbMeilleursScoresMax as integer = 12
dim meilleursScores[nbMeilleursScoresMax] as tscore
for i = 0 to nbMeilleursScoresMax
	meilleursScores[nbMeilleursScoresMax].niveau = 0
	meilleursScores[nbMeilleursScoresMax].pseudo$ = ""
	meilleursScores[nbMeilleursScoresMax].transmis$ = "N"
next i

rem ********************
rem * Exécution du programme
rem ********************
page$ = "accueil"
do
    select page$
        case "accueil":
            gosub _accueil_du_jeu
        endcase
        case "training":
            gosub _boucle_de_training
        endcase
        case "jouer":
            gosub _boucle_de_jeu
        endcase
        case "score":
            gosub _tableau_des_scores
        endcase
        case "options":
            gosub _options_du_jeu
        endcase
        case "credits":
            gosub _credits
        endcase
    endselect
loop

rem ********************
rem * affichage du tableau des scores
rem ********************
_tableau_des_scores:
    gosub _scores_load
    montrer_sprite(titreSprite)
    espacement = 10
    nombre_de_lignes = 0
    inc nombre_de_lignes
    if (langue$ = "fr")
        textes[nombre_de_lignes] = createText("Tableau des scores")
    else
        textes[nombre_de_lignes] = createText("Hall of fame")
    endif
    positionner_texte(textes[nombre_de_lignes],getSpriteY(titreSprite)+getSpriteHeight(titreSprite)+espacement)
    rem nb_carac = getVirtualWidth()/getTextSize(textes[nombre_de_lignes]) // gettextsize ressort la hauteur de la fonte, rien pour la largeur pour le moment (14/07/2012)
    nb_carac = 24
    for i = 1 to nbMeilleursScoresMax
        if (meilleursScores[i].niveau > 0)
            inc nombre_de_lignes
            textes[nombre_de_lignes] = createText(meilleursScores[i].pseudo$+spaces(nb_carac-len(meilleursScores[i].pseudo$)-len(str(meilleursScores[i].niveau)))+str(meilleursScores[i].niveau))
            positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
        endif
    next i
    setSpritePosition(idMnuJeuStop,(getVirtualWidth()-getSpriteWidth(idMnuJeuStop))/2,getVirtualHeight()-getSpriteHeight(idMnuJeuStop))
    montrer_sprite(idMnuJeuStop)
    sortie = 0
    repeat
        sync()
        // if (1 = getPointerPressed()) then sortie = getSpriteHitTest(idMnuJeuStop,getPointerX(),getPointerY())
        sortie = getPointerPressed()
    until (1 = sortie)
    masquer_sprite(titreSprite)
    masquer_sprite(idMnuJeuStop)
    for i = 1 to nombre_de_lignes
        deleteText(textes[i])
    next i
    page$ = "accueil"
return

rem ********************
rem * ecran des crédits du jeu (copyrights et remerciements)
rem ********************
_credits:
    espacement = 10
    nombre_de_lignes = 0

    setSpriteY(titreSprite,getVirtualHeight())
    montrer_sprite(titreSprite)

    if (langue$ = "fr")
        ch0$ = "Fait pour stimuler l'esprit sans aucune violence et destiné à tous les publics, Digikoo est un jeu GAMOLF."
        ch1$ = "Consultez le site"
        ch2$ = "pour voir nos autres jeux et les télécharger."
        ch3$ = "Digikoo a été développé par Patrick Prémartin pour la société Olf Software en utilisant AGK (thanks to TGC for this game development tool)."
        ch4$ = "Le thème musical du jeu est de Erin et Ginny Culp."
        ch5$ = "Les effets sonores proviennent de la librairie 500 Noises de GSP."
        ch6$ = "N'hésitez pas à nous contacter pour toute suggestion... et surtout amusez-vous !"
        ch7$ = "Tous droits réservés pour tous pays, copie interdite sans accord écrit."
    else
        ch0$ = "Done to stimulate your brain, without any violence, Digikoo is a game from GAMOLF."
        ch1$ = "Go to the web site"
        ch2$ = "to find other games and download them."
        ch3$ = "Digikoo was developped by Patrick Prémartin for company Olf Software. We used AGK (thanks to TGC for this game development tool)."
        ch4$ = "The music is copyright Erin and Ginny Culp."
        ch5$ = "Sound effects are from GSP's 500 Noises library."
        ch6$ = "Send us any suggest or comment (in french or english)... and play all over the rainbow !"
        ch7$ = "All rights reserved, don't copy anything without prior written permission."
    endif
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText(ch0$)
    positionner_texte(textes[nombre_de_lignes],getSpriteY(titreSprite)+getSpriteHeight(titreSprite)+espacement)
    setSpritePosition(idSprGAMOLF,(getVirtualWidth() - getSpriteWidth(idSprGAMOLF))/2,getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes])+espacement)
    montrer_sprite(idSprGAMOLF)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText(ch1$)
    positionner_texte(textes[nombre_de_lignes],getSpriteY(idSprGAMOLF)+getSpriteHeight(idSprGAMOLF)+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("http://www.gamolf.fr")
    idURLGamolf = textes[nombre_de_lignes]
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText(ch2$)
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)

    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText(ch3$)
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement*5)
    setSpritePosition(idSprAGK,(getVirtualWidth() - getSpriteWidth(idSprAGK))/2,getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes])+espacement)
    montrer_sprite(idSprAGK)

    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText(ch4$)
    positionner_texte(textes[nombre_de_lignes],getSpriteY(idSprAGK)+getSpriteHeight(idSprAGK)+espacement*5)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("http://www.ginnyculp.com")
    idURLGinnyCulp = textes[nombre_de_lignes]
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText(ch5$)
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement*2)

    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText(ch6$)
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement*5)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("http://www.digikoo.com")
    idURLDigikoo = textes[nombre_de_lignes]
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)

    setSpritePosition(titreSprite2,(getVirtualWidth() - getSpriteWidth(titreSprite2))/2,getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes])+espacement*5)
    montrer_sprite(titreSprite2)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText(ch7$)
    positionner_texte(textes[nombre_de_lignes],getSpriteY(titreSprite2)+getSpriteHeight(titreSprite2)+espacement)
    setTextSize(textes[nombre_de_lignes],getTextSize(textes[nombre_de_lignes])*0.8)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("(c) Olf Software 2012")
    idURLOlfSoftware = textes[nombre_de_lignes]
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)

    sortie = 0
    repeat
        for i = 1 to nombre_de_lignes
            setTextY(textes[i],getTextY(textes[i])-1)
        next i
        setSpriteY(titreSprite,getSpriteY(titreSprite)-1)
        setSpriteY(titreSprite2,getSpriteY(titreSprite2)-1)
        setSpriteY(idSprGAMOLF,getSpriteY(idSprGAMOLF)-1)
        setSpriteY(idSprAGK,getSpriteY(idSprAGK)-1)
        if (getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes]) < 0)
            ecart = 0 - getSpriteY(titreSprite) + getVirtualHeight()
            for i = 1 to nombre_de_lignes
                setTextY(textes[i],getTextY(textes[i])+ecart)
            next i
            setSpriteY(titreSprite,getSpriteY(titreSprite)+ecart)
            setSpriteY(titreSprite2,getSpriteY(titreSprite2)+ecart)
            setSpriteY(idSprGAMOLF,getSpriteY(idSprGAMOLF)+ecart)
            setSpriteY(idSprAGK,getSpriteY(idSprAGK)+ecart)
        endif
        sync()
        if (getPointerPressed() = 1)
            x = getPointerX()
            y = getPointerY()
            if (1 = getSpriteHitTest(idSprGAMOLF,x,y)) or (1 = getTextHitTest(idURLGamolf,x,y))
                openBrowser("http://www.gamolf.fr")
            elseif (1 = getTextHitTest(idURLDigikoo,x,y))
                openBrowser("http://www.digikoo.com")
            elseif (1 = getSpriteHitTest(idSprAGK,x,y))
                openBrowser("http://www.appgamekit.com")
            elseif (1 = getTextHitTest(idURLGinnyCulp,x,y))
                openBrowser("http://vasur.fr/mtr5k")
            elseif (1 = getTextHitTest(idURLOlfSoftware,x,y))
                openBrowser("http://www.olfsoftware.fr")
            else
                sortie = 1
            endif
        endif
    until (sortie = 1)
    setSpriteY(titreSprite,0)
    masquer_sprite(titreSprite)
    masquer_sprite(titreSprite2)
    masquer_sprite(idSprGAMOLF)
    masquer_sprite(idSprAGK)
    for i = 1 to nombre_de_lignes
        deleteText(textes[i])
    next i
    page$ = "accueil"
return

rem ********************
rem * ecran d'accueil du jeu
rem ********************
_accueil_du_jeu:
    rem variable servant à gérer la mise en pause du jeu
    en_pause = getFileExists("game.dat")
    rem affichage des options de menu
    montrer_sprite(titreSprite)
    if (en_pause = 1)
        nb_options = 6
    else
        nb_options = 5
    endif
    espace_avant = (getVirtualHeight() - getSpriteHeight(titreSprite) - 82 * nb_options) / (nb_options+1)
    setSpriteY(menuTrainingSprite,getSpriteY(titreSprite)+getSpriteHeight(titreSprite)+espace_avant)
    montrer_sprite(menuTrainingSprite)
    if (en_pause = 1)
        setSpriteY(menuReprendrePartie,getSpriteY(menuTrainingSprite)+getSpriteHeight(menuTrainingSprite)+espace_avant)
        montrer_sprite(menuReprendrePartie)
        setSpriteY(menuJouerSprite,getSpriteY(menuReprendrePartie)+getSpriteHeight(menuReprendrePartie)+espace_avant)
    else
        setSpriteY(menuJouerSprite,getSpriteY(menuTrainingSprite)+getSpriteHeight(menuTrainingSprite)+espace_avant)
    endif
    montrer_sprite(menuJouerSprite)
    setSpriteY(menuScoresSprite,getSpriteY(menuJouerSprite)+getSpriteHeight(menuJouerSprite)+espace_avant)
    montrer_sprite(menuScoresSprite)
    setSpriteY(menuOptionsSprite,getSpriteY(menuScoresSprite)+getSpriteHeight(menuScoresSprite)+espace_avant)
    montrer_sprite(menuOptionsSprite)
    setSpriteY(menuCreditsSprite,getSpriteY(menuOptionsSprite)+getSpriteHeight(menuOptionsSprite)+espace_avant)
    montrer_sprite(menuCreditsSprite)
    page$ = ""
    repeat
        sync()
        if (getPointerPressed() = 1)
            x = getPointerX()
            y = getPointerY()
            if (1 = getSpriteHitTest(menuTrainingSprite,x,y))
                page$ = "training"
            elseif (1 = getSpriteHitTest(menuReprendrePartie,x,y)) and (1 = getSpriteVisible(menuReprendrePartie))
                page$ = "jouer"
            elseif (1 = getSpriteHitTest(menuJouerSprite,x,y))
                page$ = "jouer"
                en_pause = 0
                if (1 = getFileExists("game.dat")) then deleteFile("game.dat")
            elseif (1 = getSpriteHitTest(menuScoresSprite,x,y))
                page$ = "score"
            elseif (1 = getSpriteHitTest(menuOptionsSprite,x,y))
                page$ = "options"
            elseif (1 = getSpriteHitTest(menuCreditsSprite,x,y))
                page$ = "credits"
            endif
        endif
    until (page$ <> "")
    masquer_sprite(titreSprite)
    masquer_sprite(menuTrainingSprite)
    masquer_sprite(menuReprendrePartie)
    masquer_sprite(menuJouerSprite)
    masquer_sprite(menuScoresSprite)
    masquer_sprite(menuOptionsSprite)
    masquer_sprite(menuCreditsSprite)
return

rem ********************
rem * ecran d'options
rem ********************
_options_du_jeu:
    montrer_sprite(titreSprite)
    setSpriteImage(menuMusicSprite,idImageMusic[music_onoff + 1])
    montrer_sprite(menuMusicSprite)
    setSpriteImage(menuSoundFXSprite,idImageSon[son_onoff + 1])
    montrer_sprite(menuSoundFXSprite)
    montrer_sprite(menuORetourSprite)
    page$ = ""
    repeat
        sync()
        if (getPointerPressed() = 1)
            x = getPointerX()
            y = getPointerY()
            if (1 = getSpriteHitTest(menuMusicSprite,x,y))
                music_onoff = 1 - music_onoff
                setSpriteImage(menuMusicSprite,idImageMusic[music_onoff + 1])
                if (music_onoff = 1)
                    playMusic(idMusiqueAmbiance)
                else
                    stopMusic()
                endif
                gosub _param_save
            elseif (1 = getSpriteHitTest(menuSoundFXSprite,x,y))
                son_onoff = 1 - son_onoff
                setSpriteImage(menuSoundFXSprite,idImageSon[son_onoff + 1])
                gosub _param_save
            elseif (1 = getSpriteHitTest(menuORetourSprite,x,y))
                page$ = "accueil"
            endif
        endif
    until (page$ <> "")
    masquer_sprite(titreSprite)
    masquer_sprite(menuMusicSprite)
    masquer_sprite(menuSoundFXSprite)
    masquer_sprite(menuORetourSprite)
return

rem ********************
rem * choix du nombre de cases pour le training
rem ********************
_training_choix:
    montrer_sprite(titreSprite)
    montrer_sprite(menuT3)
    montrer_sprite(menuT4)
    montrer_sprite(menuT5)
    montrer_sprite(menuT6)
    montrer_sprite(menuT7)
    montrer_sprite(menuT8)
    montrer_sprite(menuT9)
    montrer_sprite(menuTRetourSprite)
    nb_cases = 0
    repeat
        sync()
        if (getPointerPressed() = 1)
            x = getPointerX()
            y = getPointerY()
            if (1 = getSpriteHitTest(menuT3,x,y))
                nb_cases = 3
            elseif (1 = getSpriteHitTest(menuT4,x,y))
                nb_cases = 4
            elseif (1 = getSpriteHitTest(menuT5,x,y))
                nb_cases = 5
            elseif (1 = getSpriteHitTest(menuT6,x,y))
                nb_cases = 6
            elseif (1 = getSpriteHitTest(menuT7,x,y))
                nb_cases = 7
            elseif (1 = getSpriteHitTest(menuT8,x,y))
                nb_cases = 8
            elseif (1 = getSpriteHitTest(menuT9,x,y))
                nb_cases = 9
            elseif (1 = getSpriteHitTest(menuTRetourSprite,x,y))
                page$ = "accueil"
            endif
        endif
    until (nb_cases > 0) or (page$ <> "")
    masquer_sprite(titreSprite)
    masquer_sprite(menuT3)
    masquer_sprite(menuT4)
    masquer_sprite(menuT5)
    masquer_sprite(menuT6)
    masquer_sprite(menuT7)
    masquer_sprite(menuT8)
    masquer_sprite(menuT9)
    masquer_sprite(menuTRetourSprite)
return

rem ********************
rem * boucle principale du training
rem ********************
_boucle_de_training:
    en_training = 1
    page$ = ""
    rem choix du nombre de cases pour les grilles d'entrainement
    gosub _training_choix
    while (page$ = "")
        rem lancement du jeu avec le bon nombre de cases
        niveau = 0
        repeat
            inc niveau
            gagne = 0
            perdu = 0
            gosub _initialiser_partie
            gosub _jouer_partie
            gosub _fermer_partie
        until (perdu = 1)
        rem afficher l'écran de score suite à ce training
        gosub _training_perdu
        rem permet de retenter une nouvelle série de training
        gosub _training_choix
    endwhile
return

rem ********************
rem * boucle principale du jeu
rem ********************
_boucle_de_jeu:
    en_training = 0
    niveau = 0
    nb_cases = nb_cases_mini
    nb_level = nb_cases
    repeat
        inc niveau
        gagne = 0
        perdu = 0
        gosub _initialiser_partie
        gosub _jouer_partie
        gosub _fermer_partie
        if (gagne = 1)
            gosub _gagne
            dec nb_level
            if (nb_level < 1)
                inc nb_cases
                if (nb_cases > nb_cases_maxi) then nb_cases = nb_cases_mini
                nb_level = nb_cases
            endif
        endif
    until (perdu = 1) or (en_pause = 1)
    if (perdu = 1)
        if (1 = getFileExists("game.dat")) then deleteFile("game.dat")
        gosub _perdu
        page$ = "score"
    else
        page$ = "accueil"
    endif
return

rem ********************
rem * niveau gagné, on affiche l'info et on passe au suivant
rem ********************
_gagne:
    montrer_sprite(titreSprite)
    setSpritePosition(idMnuSuite,(getVirtualWidth()-getSpriteWidth(idMnuSuite))/2,getVirtualHeight()-getSpriteHeight(idMnuSuite))
    montrer_sprite(idMnuSuite)
    espacement = 20
    nombre_de_lignes = 0
    inc nombre_de_lignes
    if (langue$ = "fr")
        textes[nombre_de_lignes] = createText("Bien joué.")
    else
        textes[nombre_de_lignes] = createText("Well done.")
    endif
    positionner_texte(textes[nombre_de_lignes],getSpriteY(titreSprite)+getSpriteHeight(titreSprite)+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    if (niveau > 1)
        s$ = "s"
    else
        s$ = ""
    endif
    inc nombre_de_lignes
    if (langue$= "fr")
        textes[nombre_de_lignes] = createText("Vous avez réussi "+str(niveau)+" grille"+s$+".")
    else
        textes[nombre_de_lignes] = createText("You're at level "+str(niveau)+".")
    endif
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    if (langue$ = "fr")
        textes[nombre_de_lignes] = createText("On attaque la suivante ?")
    else
        textes[nombre_de_lignes] = createText("Ready to continue ?")
    endif
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    if (son_onoff = 1) then playSound(idSonVictoire)
    sortie = 0
    repeat
        sync()
        // if (1 = getPointerPressed()) then sortie = getSpriteHitTest(idMnuSuite,getPointerX(),getPointerY())
        sortie = getPointerPressed()
    until (1 = sortie)
    stopSound(idSonVictoire)
    masquer_sprite(titreSprite)
    masquer_sprite(idMnuSuite)
    for i = 1 to nombre_de_lignes
        deleteText(textes[i])
    next i
return

rem ********************
rem * niveau perdu, on arrête la partie
rem ********************
_perdu:
    dec niveau
    montrer_sprite(titreSprite)
    setSpritePosition(menuScoresSprite,(getVirtualWidth()-getSpriteWidth(menuScoresSprite))/2,getVirtualHeight()-getSpriteHeight(menuScoresSprite))
    montrer_sprite(menuScoresSprite)
    if (son_onoff = 1) then playSound(idSonDefaite)
    espacement = 20
    nombre_de_lignes = 0
    inc nombre_de_lignes
    if (langue$ = "fr")
        textes[nombre_de_lignes] = createText("Trop de rouge dans cette grille, vous avez perdu...")
    else
        textes[nombre_de_lignes] = createText("Too more red cells on this map, you lost...")
    endif
    positionner_texte(textes[nombre_de_lignes],getSpriteY(titreSprite)+getSpriteHeight(titreSprite)+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    if (niveau > 0)
        if (niveau > 1)
            s$ = "s"
        else
            s$ = ""
        endif
        inc nombre_de_lignes
        if (langue$ = "fr")
            textes[nombre_de_lignes] = createText("Pourtant, vous aviez réussi "+str(niveau)+" grille"+s$+" jusqu'à maintenant.")
        else
            textes[nombre_de_lignes] = createText("You were at level "+str(niveau)+".")
        endif
        positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
        inc nombre_de_lignes
        textes[nombre_de_lignes] = createText("")
        positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
        inc nombre_de_lignes
        if (langue$ = "fr")
            textes[nombre_de_lignes] = createText("Quel est votre nom ?")
        else
			textes[nombre_de_lignes] = createText("What's your name ?")
        endif
        positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
        chxPseudo = createEditBox()
        setEditBoxTextSize(chxPseudo,40)
        setEditBoxMaxChars(chxPseudo,20)
        setEditBoxSize(chxPseudo,20*40/2,40)
        setEditBoxPosition(chxPseudo,(getVirtualWidth()-getEditBoxWidth(chxPseudo))/2,getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes])+espacement)
        sortie = 0
        repeat
            sync()
            if (1 = getPointerPressed()) then sortie = getSpriteHitTest(menuScoresSprite,getPointerX(),getPointerY())
        until (sortie = 1)
        pseudo$ = getEditBoxText(chxPseudo)
        gosub _scores_save
        deleteEditBox(chxPseudo)
    else
        inc nombre_de_lignes
        if (langue$ = "fr")
            textes[nombre_de_lignes] = createText("Et si vous recommenciez ?")
        else
            textes[nombre_de_lignes] = createText("Do you want to play again ?")
        endif
        positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
        repeat
            sync()
        until (1 = getPointerPressed())
    endif
    stopSound(idSonDefaite)
    masquer_sprite(titreSprite)
    masquer_sprite(menuScoresSprite)
    for i = 1 to nombre_de_lignes
        deleteText(textes[i])
    next i
return

rem ********************
rem * training terminé (ou perdu)
rem ********************
_training_perdu:
    dec niveau
    montrer_sprite(titreSprite)
    setSpritePosition(idMnuJeuStop,(getVirtualWidth()-getSpriteWidth(idMnuJeuStop))/2,getVirtualHeight()-getSpriteHeight(idMnuJeuStop))
    montrer_sprite(idMnuJeuStop)
    espacement = 20
    nombre_de_lignes = 0
    inc nombre_de_lignes
    if (langue$ = "fr")
        textes[nombre_de_lignes] = createText("La fin de votre entrainement ?")
    else
        textes[nombre_de_lignes] = createText("End of your training ?")
    endif
    positionner_texte(textes[nombre_de_lignes],getSpriteY(titreSprite)+getSpriteHeight(titreSprite)+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    if (niveau > 1)
        s$ = "s"
    else
        s$ = ""
    endif
    inc nombre_de_lignes
    if (langue$ = "fr")
        textes[nombre_de_lignes] = createText("Vous avez rempli "+str(niveau)+" grille"+s$+".")
    else
        textes[nombre_de_lignes] = createText("You filled "+str(niveau)+" map"+s$+".")
    endif
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    if (son_onoff = 1) then playSound(idSonDefaite)
    sortie = 0
    repeat
        sync()
        // if (1 = getPointerPressed()) then sortie = getSpriteHitTest(idMnuJeuStop,getPointerX(),getPointerY())
        sortie = getPointerPressed()
    until (1 = sortie)
    stopSound(idSonDefaite)
    masquer_sprite(titreSprite)
    masquer_sprite(idMnuJeuStop)
    for i = 1 to nombre_de_lignes
        deleteText(textes[i])
    next i
return

rem ********************
rem * initialisation des paramètres d'un tableau
rem ********************
_initialiser_partie:
    largeur_case = getImageWidth(idImageCase)
    hauteur_case = getImageHeight(idImageCase)
    if (en_pause = 0) or (en_training = 1)
        rem ***** on commence une nouvelle partie *****
        rem Calcul du décalage en haut et en bas de l'écran pour centrer l'espace de jeu
        decalage_x = (getVirtualWidth() - nb_cases*(largeur_case+2))/2
        decalage_y = (getVirtualHeight() - getSpriteHeight(idMnuJeuPause) - (nb_cases+1)*(hauteur_case+2))/2
        rem Initialisation de la grille de jeu
        for i = 1 to nb_cases
            for j = 1 to nb_cases
                rem => mise à 0 de toutes les cases
                grille[i+j*nb_cases-nb_cases].valeur=0
                rem => dessin de la grille vierge
                idSprite = 100+i+j*nb_cases-nb_cases
                setSpritePosition(idSprite,decalage_x+(i-1)*(largeur_case+2)+1,decalage_y+(j-1)*(hauteur_case+2)+1)
                montrer_sprite(idSprite)
            next j
            rem => initialisation des chiffres et affichage sous la grille
            sprites[i].valeur = i
            setSpritePosition(i,decalage_x+(i-1)*(largeur_case+2)+1,decalage_y+nb_cases*(hauteur_case+2)+1)
            montrer_sprite(i)
            rem => initialisation du nombre de chiffres à répartir dans la grille
            numeros[i] = nb_cases
        next i
        rem => calcul aléatoire d'une grille valide par attribution de chiffres à chaque case
        for i = 1 to nb_cases
            for j = 1 to nb_cases
                boucler = 1
                num1 = random(1,nb_cases)
                num = num1
                repeat
                    ok = 1
                    k = 1
                    repeat
                        if (grille[i+k*nb_cases-nb_cases].valeur = num) or (grille[k+j*nb_cases-nb_cases].valeur = num)
                            ok = 0
                        endif
                        inc k
                    until (ok = 0) or (k > nb_cases)
                    if (ok = 1)
                        idCase = i+j*nb_cases-nb_cases
                        grille[idCase].valeur = num
                        grille[idCase].fixe = 0
                        boucler = 0
                    else
                        inc num
                        if (num > nb_cases) then num = 1
                    endif
                until (boucler=0) or (num=num1)
    /*
                // pour débogage, affiche la grille lorsqu'on tombe dans un cas non résolvable
                if (grille[i+j*nb_cases-nb_cases].valeur = 0)
                    gosub _colorise_grille
                    repeat
                        print("erreur de remplissage de grille")
                        sync()
                    until (getPointerPressed() = 1)
                endif
    */
            next j
        next i
        rem => forçage d'un nombre aléatoire de cases pour corser le jeu
        if (niveau > nb_cases*nb_cases/2)
            nb = random(nb_cases,nb_cases*nb_cases/2)
        else
            nb = random(niveau,nb_cases*nb_cases/2)
        endif
        for i = 1 to nb
            idCase = random(1,nb_cases*nb_cases)
            if (grille[idCase].fixe = 0) and (numeros[grille[idCase].valeur] > 0)
                grille[idCase].fixe = 1
                dec numeros[grille[idCase].valeur]
            endif
        next i
        rem => remise à 0 des cases non forcées afin de les laisser libres pour les choix du joueur
        for i = 1 to nb_cases
            for j = 1 to nb_cases
                if (grille[i+j*nb_cases-nb_cases].valeur = 0)
                    grille[i+j*nb_cases-nb_cases].fixe = 1
                elseif (grille[i+j*nb_cases-nb_cases].fixe = 0)
                    grille[i+j*nb_cases-nb_cases].valeur = 0
                endif
            next j
        next i
        rem backup de la grille nouvellement constituée
        if (en_training = 0) then gosub _partie_save
    else
        rem ***** on reprend une partie qui était en pause *****
        if (1 = getFileExists("game.dat")) then gosub _partie_load
        rem Calcul du décalage en haut et en bas de l'écran pour centrer l'espace de jeu
        decalage_x = (getVirtualWidth() - nb_cases*(largeur_case+2))/2
        decalage_y = (getVirtualHeight() - getSpriteHeight(idMnuJeuPause) - (nb_cases+1)*(hauteur_case+2))/2
        rem on repositionne les sprites et on les affiche
        for i = 1 to nb_cases
            setSpriteSize(i,largeur_case,hauteur_case)
            setSpritePosition(i,decalage_x+(i-1)*(getImageWidth(idImageCase)+2)+1,decalage_y+nb_cases*(getImageHeight(idImageCase)+2)+1)
            montrer_sprite(i)
            for j = 1 to nb_cases
                rem => dessin de la grille vierge
                idSprite = 100+i+j*nb_cases-nb_cases
                setSpriteSize(idSprite,largeur_case,hauteur_case)
                setSpritePosition(idSprite,decalage_x+(i-1)*(getImageWidth(idImageCase)+2)+1,decalage_y+(j-1)*(getImageHeight(idImageCase)+2)+1)
                montrer_sprite(idSprite)
            next j
        next i
    endif

    rem Positionnement et affichage des boutons du jeu
    decalage_x = (getVirtualWidth()-getSpriteWidth(idMnuJeuStop)*2)/3
    if (en_training = 1)
        setSpritePosition(idMnuJeuStop,decalage_x,getVirtualHeight()-getSpriteHeight(idMnuJeuStop))
        montrer_sprite(idMnuJeuStop)
    else
        setSpritePosition(idMnuJeuPause,decalage_x,getVirtualHeight()-getSpriteHeight(idMnuJeuPause))
        montrer_sprite(idMnuJeuPause)
    endif
    setSpriteImage(idMnuJeuOptions,idImageMusic[music_onoff + 1])
    setSpritePosition(idMnuJeuOptions,getVirtualWidth()-getSpriteWidth(idMnuJeuOptions)-decalage_x,getVirtualHeight()-getSpriteHeight(idMnuJeuPause))
    montrer_sprite(idMnuJeuOptions)
return

rem ********************
rem * fin d'une partie
rem ********************
_fermer_partie:
    for i = 1 to nb_cases_maxi
        rem suppression des sprites des jetons
        masquer_sprite(i)
        for j = 1 to nb_cases_maxi
            rem suppression des sprites de la grille de jeu
            masquer_sprite(100+i+j*nb_cases_maxi-nb_cases_maxi)
        next j
    next i
    masquer_sprite(idMnuJeuStop)
    masquer_sprite(idMnuJeuPause)
    masquer_sprite(idMnuJeuOptions)
return

rem ********************
rem * déroulement d'un niveau de jeu
rem ********************
_jouer_partie:
    en_pause = 0
    selectionne = 0
    gosub _colorise_grille
    repeat
/*
        // pour débogage: affiche les valeurs clés de la phase de jeu
        print(selectionne)
        print(clique)
        if (clique <> 0)
            print(getSpriteImageID(clique))
            print(getSpriteVisible(clique))
            print(getSpriteActive(clique))
            if (clique > 100) and (clique < 100+nb_cases*nb_cases+1)
                print(grille[clique-100].valeur)
                print(grille[clique-100].fixe)
            endif
        endif
*/
        sync()
        rem gestion des clics a l'ecran
        if (getPointerPressed()=1)
            x = getPointerX()
            y = getPointerY()
            clique = 0
            rem test de clic sur les chiffres à positionner
            for i = 1 to nb_cases
                if (1 = getSpriteHitTest(i,x,y)) then clique = i
            next i
            rem test de clic sur la grille
            for i = 101 to 100+nb_cases*nb_cases
                if (1 = getSpriteHitTest(i,x,y)) then clique = i
            next i
            if (clique >= 1) and (clique <= nb_cases)
                rem on a clique sur un chiffre
                if (numeros[clique] > 0)
                    ancien_selectionne = selectionne
                    rem ce chiffre est encore disponible pour répartition sur la grille
                    rem il y avait deja un chiffre selectionne, on le deselectionne
                    if (selectionne > 0) then selectionne = 0
                    rem on selectionne le chiffre choisi, à condition que cene soit pas celui qui l'était déjà
                    if (ancien_selectionne <> clique) then selectionne = clique
                    gosub _colorise_grille
                endif
                if (en_training = 0) then gosub _partie_save
            elseif (clique > 100) and (clique <= 100+nb_cases*nb_cases)
                rem on a clique sur la grille
                idCase = clique-100
                rem si la case cliquée est libre, on traite le clic, dans le cas contraire on l'ignore
                if (grille[idCase].fixe = 0)
                    rem => s'il y a un chiffre dans la case, on le retire
                    ancienne_valeur = grille[idCase].valeur
                    if (grille[idCase].valeur > 0)
                        inc numeros[grille[idCase].valeur]
                        grille[idCase].valeur = 0
                    endif
                    if (ancienne_valeur <> selectionne)
                        rem => s'il y avait un chiffre sélectionné, on le met sur la case de la grille, à condition qu'il n'y était pas déjà
                        grille[idCase].valeur = selectionne
                        dec numeros[grille[idCase].valeur]
                        if (numeros[grille[idCase].valeur] < 1) then selectionne = 0
                    endif
                    gosub _colorise_grille
                endif
                if (en_training = 0) then gosub _partie_save
            elseif (1 = getSpriteHitTest(idMnuJeuPause,x,y)) and (1 = getSpriteVisible(idMnuJeuPause))
                en_pause = 1
                gosub _partie_save
            elseif (1 = getSpriteHitTest(idMnuJeuOptions,x,y)) and (1 = getSpriteVisible(idMnuJeuOptions))
                music_onoff = 1 - music_onoff
                setSpriteImage(idMnuJeuOptions,idImageMusic[music_onoff + 1])
                if (music_onoff = 1)
                    playMusic(idMusiqueAmbiance)
                else
                    stopMusic()
                endif
                gosub _param_save
            elseif (1 = getSpriteHitTest(idMnuJeuStop,x,y)) and (1 = getSpriteVisible(idMnuJeuStop))
                perdu = 1
            endif
        endif
    until (gagne = 1) or (perdu = 1) or (en_pause = 1)
return

rem ********************
rem * recalcul des couleurs des différents jetons sur la grille et détermination de la victoire/défaite
rem ********************
_colorise_grille:
    for i = 1 to nb_cases
        for j = 1 to nb_cases
            if (grille[i+j*nb_cases-nb_cases].fixe = 1)
                if (grille[i+j*nb_cases-nb_cases].valeur = 0)
                    setSpriteImage(100+i+j*nb_cases-nb_cases,idImageCaseAnnulee)
                else
                    setSpriteImage(100+i+j*nb_cases-nb_cases,chiffres[grille[i+j*nb_cases-nb_cases].valeur].noir)
                endif
            elseif (grille[i+j*nb_cases-nb_cases].valeur > 0)
                setSpriteImage(100+i+j*nb_cases-nb_cases,chiffres[grille[i+j*nb_cases-nb_cases].valeur].vert)
            else
                setSpriteImage(100+i+j*nb_cases-nb_cases,idImageCase)
            endif
        next j
    next i
    chiffres_poses = 0
    erreur = 0
    for i = 1 to nb_cases
        for j = 1 to nb_cases
            ok = 1
            valeur = grille[i+j*nb_cases-nb_cases].valeur
            if (grille[i+j*nb_cases-nb_cases].fixe = 1)
                inc chiffres_poses
            elseif (valeur > 0)
                inc chiffres_poses
                for k = 1 to nb_cases
                    if (k <> i) and (grille[k+j*nb_cases-nb_cases].valeur = valeur)
                        if (grille[k+j*nb_cases-nb_cases].fixe = 0) then setSpriteImage(100+k+j*nb_cases-nb_cases,chiffres[valeur].rouge)
                        ok = 0
                        inc erreur
                    endif
                    if (k <> j) and (grille[i+k*nb_cases-nb_cases].valeur = valeur)
                        if (grille[i+k*nb_cases-nb_cases].fixe = 0) then setSpriteImage(100+i+k*nb_cases-nb_cases,chiffres[valeur].rouge)
                        ok = 0
                        inc erreur
                    endif
                next k
                if (ok = 0) then setSpriteImage(100+i+j*nb_cases-nb_cases,chiffres[valeur].rouge)
            endif
        next j
        if (numeros[i]>0)
            if (selectionne = i)
                setSpriteImage(i,chiffres[i].vert)
            else
                setSpriteImage(i,chiffres[i].jaune)
            endif
            montrer_sprite(i)
        else
            masquer_sprite(i)
        endif
    next i
    if (chiffres_poses = nb_cases*nb_cases)
        if (erreur = 0)
            gagne = 1
        else
            perdu = 1
        endif
    endif
return

rem ********************
rem * chargement des paramètres de l'application
rem ********************
_param_load:
    langue$=GetDeviceLanguage()
    if (langue$ <> "fr") and (langue$ <> "en")
		langue$ = "en"
	endif
    music_onoff = 1
    son_onoff = 1
    //log$=""
    if (1 = getFileExists("settings.dat"))
        //log$ = log$ + "settings.dat present"+chr(10)
        f = openToRead("settings.dat")
        while (0 = fileEOF(f))
            ch$ = readLine(f)
            //log$ = log$ + ch$ + chr(10)
            //log$ = log$ + "count : " + str(countStringTokens(ch$,"=")) + chr(10)
            if (2 = countStringTokens(ch$,"="))
                key$ = getStringToken(ch$,"=",1)
                //log$ = log$ + "cle = " + key$ + chr(10)
                value$ = getStringToken(ch$,"=",2)
                //log$ = log$ + "valeur = " + value$ + chr(10)
remstart
                if (key$ = "langue")
                   langue$ = value$
                else
remend
				if (key$ = "music_onoff")
                    music_onoff = val(value$)
                    if (music_onoff <> 0) then music_onoff = 1
                elseif (key$ = "son_onoff")
                    son_onoff = val(value$)
                    if (son_onoff <> 0) then son_onoff = 1
                endif
            endif
        endwhile
        closeFile(f)
    //else
        //log$ = log$ + "settings.dat absent"+chr(10)
    endif
    //repeat
        //print(log$)
        //sync()
    //until (1 = getPointerPressed())
return

rem ********************
rem * sauvegarde des paramètres de l'application
rem ********************
_param_save:
    f = openToWrite("settings.dat",0)
remstart
    writeLine(f,"langue="+langue$)
remend
    writeLine(f,"music_onoff="+str(music_onoff))
    writeLine(f,"son_onoff="+str(son_onoff))
    closeFile(f)
return

rem ********************
rem * rechargement d'une partie enregistrée
rem ********************
_partie_load:
    if (1 = getFileExists("game.dat"))
        f = openToRead("game.dat")
        while (0 = fileEOF(f))
            ch$ = readLine(f)
            if (2 = countStringTokens(ch$,"="))
                key$ = getStringToken(ch$,"=",1)
                value$ = getStringToken(ch$,"=",2)
                if (key$ = "nb_cases")
                    nb_cases = val(value$)
                    if (nb_cases < nb_cases_mini)
                        nb_cases = nb_cases_mini
                    elseif (nb_cases > nb_cases_maxi)
                        nb_cases = nb_cases_maxi
                    endif
                elseif (key$ = "nb_level")
                    nb_level = val(value$)
                    if (nb_level > nb_cases)
                        nb_level = nb_cases
                    elseif (nb_level < 1)
                        nb_level = 1
                    endif
                elseif (key$ = "niveau")
                    niveau = val(value$)
                    if (niveau < 1)
                        niveau = 1
                    endif
                elseif (key$ = "grille")
                    for i = 1 to nb_cases*nb_cases
                        if (i <= countStringTokens(value$,","))
                            ch$ = getStringToken(value$,",",i)
                            if (2 = countStringTokens(ch$,"|"))
                                grille[i].fixe = val(getStringToken(ch$,"|",1))
                                if (0 <> grille[i].fixe) then grille[i].fixe = 1
                                grille[i].valeur = val(getStringToken(ch$,"|",2))
                                if (grille[i].valeur < 0) or (grille[i].valeur > nb_cases)
                                    grille[i].fixe = 0
                                    grille[i].valeur= 0
                                endif
                            else
                                grille[i].fixe = 0
                                grille[i].valeur = 0
                            endif
                        else
                            grille[i].fixe = 0
                            grille[i].valeur = 0
                        endif
                    next i
                elseif (key$ = "numeros")
                    for i = 1 to nb_cases
                        if (i <= countStringTokens(value$,","))
                            numeros[i] = val(getStringToken(value$,",",i))
                            if (numeros[i] < 1) or (numeros[i] > nb_cases) then numeros[i] = 0
                        else
                            numeros[i] = 0
                        endif
                    next i
                endif
            endif
        endwhile
        closeFile(f)
/*
        // pour débogage : on réécrit ce qu'on vient de charger histoire de s'assurer que c'est bien pris en compte
        f = openToWrite("game2.dat",0)
        rem backup des variables de base
        writeLine(f,"nb_cases="+str(nb_cases))
        writeLine(f,"nb_level="+str(nb_level))
        writeLine(f,"niveau="+str(niveau))
        rem backup de la grille de jeu
        ch$ = ""
        for i = 1 to nb_cases*nb_cases
            if (i > 1)
                ch$ = ch$ + ","
            endif
            ch$ = ch$ + str(grille[i].fixe) + "|" + str(grille[i].valeur)
        next i
        writeLine(f,"grille="+ch$)
        rem backup de la liste des chiffres
        ch$ = ""
        for i = 1 to nb_cases
            if (i > 1)
                ch$ = ch$ + ","
            endif
            ch$ = ch$ + str(numeros[i])
        next i
        writeLine(f,"numeros="+ch$)
        closeFile(f)
        // fin pour débogage
*/
    endif
return

rem ********************
rem * sauvegarde des paramètres de la partie en cours pour gérer la mise en veille de l'application et sa mise en pause
rem ********************
_partie_save:
    f = openToWrite("game.dat",0)
    rem backup des variables de base
    writeLine(f,"nb_cases="+str(nb_cases))
    writeLine(f,"nb_level="+str(nb_level))
    writeLine(f,"niveau="+str(niveau))
    rem backup de la grille de jeu
    ch$ = ""
    for i = 1 to nb_cases*nb_cases
        if (i > 1) then ch$ = ch$ + ","
        ch$ = ch$ + str(grille[i].fixe) + "|" + str(grille[i].valeur)
    next i
    writeLine(f,"grille="+ch$)
    rem backup de la liste des chiffres
    ch$ = ""
    for i = 1 to nb_cases
        if (i > 1) then ch$ = ch$ + ","
        ch$ = ch$ + str(numeros[i])
    next i
    writeLine(f,"numeros="+ch$)
    closeFile(f)
return

rem ********************
rem * chargement des 20 meilleurs scores
rem ********************
_scores_load:
    for i = 1 to nbMeilleursScoresMax
        meilleursScores[i].pseudo$ = ""
        meilleursScores[i].niveau = 0
        meilleursScores[i].transmis$ = "N"
    next i
    score1 as tscore
    score2 as tscore
    if (1 = getFileExists("scores.dat"))
        f = openToRead("scores.dat")
        while (0 = FileEOF(f))
            ch$ = readLine(f)
            if (3 = CountStringTokens(ch$,"|"))
                score1.pseudo$ = getStringToken(ch$,"|",1)
                score1.niveau = val(getStringToken(ch$,"|",2))
                score1.transmis$ = getStringToken(ch$,"|",3)
                phase = 1
                for i = 1 to nbMeilleursScoresMax
                    if (phase = 1) and (meilleursScores[i].niveau < score1.niveau)
                        score2 = meilleursScores[i]
/*                        score2.pseudo$ = meilleursScores[i].pseudo$
                        score2.niveau = meilleursScores[i].niveau
                        score2.transmis$ = meilleursScores[i].transmis$*/
                        meilleursScores[i] = score1
/*                        meilleursScores[i].pseudo$ = score1.pseudo$
                        meilleursScores[i].niveau = score1.niveau
                        meilleursScores[i].transmis$ = score1.transmis$*/
                        phase = 2
                    elseif (phase = 2)
                        score1 = score2
/*                        score1.pseudo$ = score2.pseudo$
                        score1.niveau = score2.niveau
                        score1.transmis$ = score2.transmis$*/
                        score2 = meilleursScores[i]
/*                        score2.pseudo$ = meilleursScores[i].pseudo$
                        score2.niveau = meilleursScores[i].niveau
                        score2.transmis$ = meilleursScores[i].transmis$*/
                        meilleursScores[i] = score1
/*                        meilleursScores[i].pseudo$ = score1.pseudo$
                        meilleursScores[i].niveau = score1.niveau
                        meilleursScores[i].transmis$ = score1.transmis$*/
                    endif
                next i
            endif
        endwhile
        closeFile(f)
    endif
return

rem ********************
rem * enregistrement du score de la partie qui vient de se terminer
rem ********************
_scores_save:
    if (pseudo$ <> "") and (niveau > 0)
        f = openToWrite("scores.dat",1)
        writeLine(f,left(pseudo$,20)+"|"+str(niveau)+"|N")
        closeFile(f)
    endif
return

rem ********************
rem * chargement des images dépendant de la langue du jeu
rem ********************
charger_images:
    imgTraining = 500
    if (getImageExists(imgTraining)) then deleteImage(imgTraining)
    loadImage(imgTraining,langue$+"-training.png")
    imgRestart = imgTraining+1
    if (getImageExists(imgRestart)) then deleteImage(imgRestart)
    loadImage(imgRestart,langue$+"-restart.png")
    imgPlay = imgRestart+1
    if (getImageExists(imgPlay)) then deleteImage(imgPlay)
    loadImage(imgPlay,langue$+"-play.png")
    imgScore = imgPlay+1
    if (getImageExists(imgScore)) then deleteImage(imgScore)
    loadImage(imgScore,langue$+"-score.png")
    imgOptions= imgScore+1
    if (getImageExists(imgOptions)) then deleteImage(imgOptions)
    loadImage(imgOptions,langue$+"-options.png")
    imgCredits = imgOptions+1
    if (getImageExists(imgCredits)) then deleteImage(imgCredits)
    loadImage(imgCredits,langue$+"-credits.png")
    imgMusicOn = imgCredits+1
    if (getImageExists(imgMusicOn)) then deleteImage(imgMusicOn)
    loadImage(imgMusicOn,langue$+"-music-on.png")
    imgMusicOff = imgMusicOn+1
    if (getImageExists(imgMusicOff)) then deleteImage(imgMusicOff)
    loadImage(imgMusicOff,langue$+"-music-off.png")
    imgSoundOn = imgMusicOff+1
    if (getImageExists(imgSoundOn)) then deleteImage(imgSoundOn)
    loadImage(imgSoundOn,langue$+"-sound-on.png")
    imgSoundOff = imgSoundOn+1
    if (getImageExists(imgSoundOff)) then deleteImage(imgSoundOff)
    loadImage(imgSoundOff,langue$+"-sound-off.png")
    imgBack = imgSoundOff+1
    if (getImageExists(imgBack)) then deleteImage(imgBack)
    loadImage(imgBack,langue$+"-back.png")
    imgPause = imgBack+1
    if (getImageExists(imgPause)) then deleteImage(imgPause)
    loadImage(imgPause,langue$+"-pause.png")
    imgNext = imgPause+1
    if (getImageExists(imgNext)) then deleteImage(imgNext)
    loadImage(imgNext,langue$+"-next.png")
return

rem ********************
rem * fonction permettant le chargement des sprites des différents menus
rem ********************
function charge_menu(idSprite,idImage,menuPrecedent,espace_avant)
    createSprite(idSprite,idImage)
    if (menuPrecedent = 0)
        setSpritePosition(idSprite,(getVirtualWidth() - getSpriteWidth(idSprite))/2,espace_avant)
    else
        setSpritePosition(idSprite,(getVirtualWidth() - getSpriteWidth(idSprite))/2,getSpriteY(menuPrecedent)+getSpriteHeight(menuPrecedent)+espace_avant)
    endif
    masquer_sprite(idSprite)
endfunction idSprite

rem ********************
rem * cacher et désactiver un sprite pour économiser des ressources
rem ********************
function masquer_sprite(idSprite)
    setSpriteVisible(idSprite,0)
    setSpriteActive(idSprite,0)
endfunction

rem ********************
rem * réactiver et montrer un sprite pour économiser des ressources
rem ********************
function montrer_sprite(idSprite)
    setSpriteVisible(idSprite,1)
    setSpriteActive(idSprite,1)
endfunction

rem ********************
rem * positionnement des textes et paramétrage standard de ceux-ci
rem ********************
function positionner_texte(id,y)
    setTextPosition(id,getVirtualWidth()/2,y)
    setTextAlignment(id,1)
    setTextSize(id,40)
    setTextMaxWidth(id,getVirtualWidth())
endfunction
